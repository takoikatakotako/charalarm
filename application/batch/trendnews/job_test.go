package trendnews

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/takoikatakotako/charalarm/api/service/llm"
)

type fakeSearcher struct {
	results map[string][]Story
	errs    map[string]error
}

func (f *fakeSearcher) Search(_ context.Context, query string, _ int, _ int) ([]Story, error) {
	if err := f.errs[query]; err != nil {
		return nil, err
	}
	return f.results[query], nil
}

type fakeLLM struct {
	answer   string
	err      error
	messages []llm.Message
}

func (f *fakeLLM) Chat(_ context.Context, messages []llm.Message) (string, error) {
	f.messages = messages
	return f.answer, f.err
}

type fakePublisher struct {
	key, contentType, cacheControl string
	data                           []byte
	calls                          int
}

func (f *fakePublisher) Publish(key, contentType, cacheControl string, data []byte) error {
	f.calls++
	f.key, f.contentType, f.cacheControl, f.data = key, contentType, cacheControl, data
	return nil
}

func story(id, name string) Story {
	return Story{ID: id, Name: name, Hook: name + "のつかみ", Summary: name + "の要約", UpdatedAt: "2026-11-04T09:46:08.000Z"}
}

func TestJobRun(t *testing.T) {
	now := time.Date(2026, 11, 4, 19, 0, 0, 0, time.UTC)

	t.Run("集めて重なりを除き、Gemini が選んだ順に配る", func(t *testing.T) {
		searcher := &fakeSearcher{results: map[string][]Story{
			"ゲーム": {story("1", "人狼バーガー"), story("2", "けがの話")},
			"アニメ": {story("1", "人狼バーガー"), story("3", "薬屋のひとりごと")},
			"マンガ": {{ID: "4", Name: "要約なし"}, story("5", "Fans Celebrate Amuro Ray's Birthday")},
		}}
		model := &fakeLLM{answer: "3\n1.\n"}
		publisher := &fakePublisher{}
		job := Job{Searcher: searcher, LLM: model, Publisher: publisher, Now: func() time.Time { return now }}

		require.NoError(t, job.Run(context.Background()))
		assert.Equal(t, FeedKey, publisher.key)
		assert.Equal(t, "application/json", publisher.contentType)
		assert.Equal(t, feedCacheControl, publisher.cacheControl)

		var feed Feed
		require.NoError(t, json.Unmarshal(publisher.data, &feed))
		assert.Equal(t, "2026-11-04T19:00:00Z", feed.GeneratedAt)
		require.Len(t, feed.Items, 2)
		assert.Equal(t, "薬屋のひとりごと", feed.Items[0].Title)
		assert.Equal(t, "人狼バーガー", feed.Items[1].Title)
		assert.Equal(t, "人狼バーガーのつかみ", feed.Items[1].Hook)

		// Gemini には番号つきで 3 件 (重なりと要約なしを除く) を渡す
		user := model.messages[len(model.messages)-1].Content
		assert.Contains(t, user, "1. 人狼バーガー")
		assert.Contains(t, user, "3. 薬屋のひとりごと")
		assert.NotContains(t, user, "要約なし")
		assert.NotContains(t, user, "Amuro", "日本語でないニュースは除く")
	})

	t.Run("一部の検索で失敗しても、取れた分で続ける", func(t *testing.T) {
		searcher := &fakeSearcher{
			results: map[string][]Story{"アニメ": {story("3", "薬屋のひとりごと")}},
			errs:    map[string]error{"ゲーム": errors.New("status 503")},
		}
		publisher := &fakePublisher{}
		job := Job{Searcher: searcher, LLM: &fakeLLM{answer: "1"}, Publisher: publisher}
		require.NoError(t, job.Run(context.Background()))
		assert.Equal(t, 1, publisher.calls)
	})

	t.Run("取れない・選べない・Gemini が失敗したら、前の一覧を残す", func(t *testing.T) {
		cases := map[string]Job{
			"取れない":       {Searcher: &fakeSearcher{}, LLM: &fakeLLM{answer: "1"}},
			"選べるものがない":   {Searcher: &fakeSearcher{results: map[string][]Story{"ゲーム": {story("1", "a")}}}, LLM: &fakeLLM{answer: "なし"}},
			"Gemini が失敗": {Searcher: &fakeSearcher{results: map[string][]Story{"ゲーム": {story("1", "a")}}}, LLM: &fakeLLM{err: errors.New("timeout")}},
		}
		for name, job := range cases {
			t.Run(name, func(t *testing.T) {
				publisher := &fakePublisher{}
				job.Publisher = publisher
				assert.Error(t, job.Run(context.Background()))
				assert.Equal(t, 0, publisher.calls)
			})
		}
	})
}

func TestPickStories(t *testing.T) {
	stories := []Story{story("a", "A"), story("b", "B"), story("c", "C")}
	ids := func(s []Story) []string {
		out := []string{}
		for _, x := range s {
			out = append(out, x.ID)
		}
		return out
	}
	assert.Equal(t, []string{"c", "a"}, ids(pickStories(stories, "3\n 1 \n", 5)))
	assert.Equal(t, []string{"b"}, ids(pickStories(stories, "2\n2\n0\n4\nx", 5)), "重なり・範囲外・数字でないものは捨てる")
	assert.Equal(t, []string{"a", "b"}, ids(pickStories(stories, "1\n2\n3", 2)), "上限まで")
	assert.Empty(t, pickStories(stories, "なし", 5))
}

func TestXClientSearch(t *testing.T) {
	var gotQuery, gotAuth string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotQuery = r.URL.RawQuery
		gotAuth = r.Header.Get("Authorization")
		assert.Equal(t, "ja", r.Header.Get("Accept-Language"))
		assert.Equal(t, "/2/news/search", r.URL.Path)
		_, _ = w.Write([]byte(`{"data":[{"id":"1","name":"人狼バーガー","hook":"h","summary":"s","category":"Entertainment","updated_at":"2026-11-04T09:46:08.000Z"}],"meta":{"result_count":1}}`))
	}))
	defer server.Close()

	client := NewXClient("token")
	client.BaseURL = server.URL
	stories, err := client.Search(context.Background(), "ゲーム", 10, 24)
	require.NoError(t, err)
	require.Len(t, stories, 1)
	assert.Equal(t, "人狼バーガー", stories[0].Name)
	assert.Equal(t, "2026-11-04T09:46:08.000Z", stories[0].UpdatedAt)
	assert.Equal(t, "Bearer token", gotAuth)
	assert.Contains(t, gotQuery, "max_age_hours=24")
	assert.Contains(t, gotQuery, "query=%E3%82%B2%E3%83%BC%E3%83%A0")

	server.Close()
	_, err = client.Search(context.Background(), "ゲーム", 10, 24)
	assert.Error(t, err)
}

func TestIsJapanese(t *testing.T) {
	assert.True(t, isJapanese("『薬屋のひとりごと』劇場版"))
	assert.True(t, isJapanese("JO1「ANIMAL」全米デビュー"))
	assert.False(t, isJapanese("Fans Celebrate Amuro Ray's Birthday"))
	assert.False(t, isJapanese(""))
}

func TestXClientSearchStatusError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusPaymentRequired)
	}))
	defer server.Close()
	client := NewXClient("token")
	client.BaseURL = server.URL
	_, err := client.Search(context.Background(), "ゲーム", 10, 24)
	require.Error(t, err)
	assert.True(t, strings.Contains(err.Error(), "402"))
}
