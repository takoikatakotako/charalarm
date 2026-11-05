package trendnews

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
	files map[string][]byte
	order []string
	calls int
}

func (f *fakePublisher) Publish(key, contentType, cacheControl string, data []byte) error {
	f.calls++
	if f.files == nil {
		f.files = map[string][]byte{}
	}
	f.files[key] = data
	f.order = append(f.order, key)
	if contentType != "application/json" || cacheControl != feedCacheControl {
		return errors.New("unexpected headers")
	}
	return nil
}

func story(id, name string) Story {
	return Story{ID: id, Name: name, Hook: name + "のつかみ", Summary: name + "の要約", UpdatedAt: "2026-11-04T09:46:08.000Z"}
}

// answer は Gemini の答え。番号ごとに日本語版・英語版を付ける
func answer(numbers ...int) string {
	items := []string{}
	for _, n := range numbers {
		items = append(items, fmt.Sprintf(`{"number":%d,"ja":{"title":"見出し%d","hook":"つかみ%d","summary":"要約%d"},"en":{"title":"Title %d","hook":"Hook %d","summary":"Summary %d"}}`, n, n, n, n, n, n, n))
	}
	return "```json\n{\"items\":[" + strings.Join(items, ",") + "]}\n```"
}

func decodeFeed(t *testing.T, data []byte) Feed {
	t.Helper()
	var feed Feed
	require.NoError(t, json.Unmarshal(data, &feed))
	return feed
}

func TestJobRun(t *testing.T) {
	now := time.Date(2026, 11, 4, 19, 0, 0, 0, time.UTC)

	t.Run("集めて重なりを除き、Gemini が選んだ順に日本語版と英語版を配る", func(t *testing.T) {
		searcher := &fakeSearcher{results: map[string][]Story{
			"ゲーム": {story("1", "人狼バーガー"), story("2", "けがの話")},
			"アニメ": {story("1", "人狼バーガー"), story("3", "Fans Celebrate Amuro Ray's Birthday")},
			"マンガ": {{ID: "4", Name: "要約なし"}},
		}}
		model := &fakeLLM{answer: answer(3, 1)}
		publisher := &fakePublisher{}
		job := Job{Searcher: searcher, LLM: model, Publisher: publisher, Now: func() time.Time { return now }}

		require.NoError(t, job.Run(context.Background()))
		assert.Equal(t, []string{FeedKeyEnglish, FeedKeyJapanese}, publisher.order, "日本語は最後に置く")

		ja := decodeFeed(t, publisher.files[FeedKeyJapanese])
		assert.Equal(t, "2026-11-04T19:00:00Z", ja.GeneratedAt)
		require.Len(t, ja.Items, 2)
		assert.Equal(t, FeedItem{ID: "3", Title: "見出し3", Hook: "つかみ3", Summary: "要約3", UpdatedAt: "2026-11-04T09:46:08.000Z"}, ja.Items[0])
		assert.Equal(t, "1", ja.Items[1].ID)

		en := decodeFeed(t, publisher.files[FeedKeyEnglish])
		require.Len(t, en.Items, 2)
		assert.Equal(t, "Title 3", en.Items[0].Title)
		assert.Equal(t, ja.GeneratedAt, en.GeneratedAt)

		// Gemini には番号つきで 3 件 (重なりと要約なしを除く。英語のニュースも渡す) を渡す
		user := model.messages[len(model.messages)-1].Content
		assert.Contains(t, user, "1. 人狼バーガー")
		assert.Contains(t, user, "3. Fans Celebrate Amuro Ray's Birthday")
		assert.NotContains(t, user, "要約なし")
	})

	t.Run("一部の検索で失敗しても、取れた分で続ける", func(t *testing.T) {
		searcher := &fakeSearcher{
			results: map[string][]Story{"アニメ": {story("3", "薬屋のひとりごと")}},
			errs:    map[string]error{"ゲーム": errors.New("status 503")},
		}
		publisher := &fakePublisher{}
		job := Job{Searcher: searcher, LLM: &fakeLLM{answer: answer(1)}, Publisher: publisher}
		require.NoError(t, job.Run(context.Background()))
		assert.Equal(t, 2, publisher.calls)
	})

	t.Run("取れない・選べない・Gemini が失敗・答えが JSON でないなら、前の一覧を残す", func(t *testing.T) {
		one := map[string][]Story{"ゲーム": {story("1", "a")}}
		cases := map[string]Job{
			"取れない":         {Searcher: &fakeSearcher{}, LLM: &fakeLLM{answer: answer(1)}},
			"選べるものがない":     {Searcher: &fakeSearcher{results: one}, LLM: &fakeLLM{answer: `{"items":[]}`}},
			"Gemini が失敗":   {Searcher: &fakeSearcher{results: one}, LLM: &fakeLLM{err: errors.New("timeout")}},
			"答えが JSON でない": {Searcher: &fakeSearcher{results: one}, LLM: &fakeLLM{answer: "1"}},
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
	ids := func(s []SelectedStory) []string {
		out := []string{}
		for _, x := range s {
			out = append(out, x.Story.ID)
		}
		return out
	}
	pick := func(answer string, limit int) []SelectedStory {
		selected, err := pickStories(stories, answer, limit)
		require.NoError(t, err)
		return selected
	}
	assert.Equal(t, []string{"c", "a"}, ids(pick(answer(3, 1), 5)))
	assert.Equal(t, []string{"b"}, ids(pick(answer(2, 2, 0, 4), 5)), "重なり・範囲外は捨てる")
	assert.Equal(t, []string{"a", "b"}, ids(pick(answer(1, 2, 3), 2)), "上限まで")
	assert.Empty(t, pick(`{"items":[{"number":1,"ja":{"title":"見出し","summary":"要約"},"en":{"title":"","summary":""}}]}`, 5), "英語版が欠けていたら捨てる")
	_, err := pickStories(stories, "なし", 5)
	assert.Error(t, err)
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
