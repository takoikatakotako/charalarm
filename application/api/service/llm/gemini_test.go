package llm

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestToGeminiContents(t *testing.T) {
	t.Run("先頭の system は systemInstruction、途中の system は user の発言にする", func(t *testing.T) {
		system, contents := toGeminiContents([]Message{
			{Role: RoleSystem, Content: "キャラ設定"},
			{Role: RoleSystem, Content: "記憶"},
			{Role: RoleUser, Content: "おはよう"},
			{Role: RoleAssistant, Content: "おはようなのだ"},
			{Role: RoleSystem, Content: "電話を切って"},
		})
		assert.Equal(t, &geminiContent{Parts: []geminiPart{{Text: "キャラ設定"}, {Text: "記憶"}}}, system)
		assert.Equal(t, []geminiContent{
			{Role: "user", Parts: []geminiPart{{Text: "おはよう"}}},
			{Role: "model", Parts: []geminiPart{{Text: "おはようなのだ"}}},
			{Role: "user", Parts: []geminiPart{{Text: "電話を切って"}}},
		}, contents)
	})

	t.Run("system だけなら最後の system を user の発言にする", func(t *testing.T) {
		system, contents := toGeminiContents([]Message{
			{Role: RoleSystem, Content: "キャラ設定"},
			{Role: RoleSystem, Content: "電話に出たところ"},
		})
		assert.Equal(t, &geminiContent{Parts: []geminiPart{{Text: "キャラ設定"}}}, system)
		assert.Equal(t, []geminiContent{{Role: "user", Parts: []geminiPart{{Text: "電話に出たところ"}}}}, contents)
	})

	t.Run("system が 1 つだけなら systemInstruction は無し", func(t *testing.T) {
		system, contents := toGeminiContents([]Message{{Role: RoleSystem, Content: "電話に出たところ"}})
		assert.Nil(t, system)
		assert.Len(t, contents, 1)
	})

	t.Run("同じ role が続いたらまとめる", func(t *testing.T) {
		_, contents := toGeminiContents([]Message{
			{Role: RoleUser, Content: "a"},
			{Role: RoleSystem, Content: "b"},
		})
		assert.Equal(t, []geminiContent{{Role: "user", Parts: []geminiPart{{Text: "a"}, {Text: "b"}}}}, contents)
	})
}

func TestGeminiClientChat(t *testing.T) {
	var gotPath string
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		b, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(b, &gotBody)
		_, _ = w.Write([]byte(`{"candidates":[{"content":{"role":"model","parts":[
			{"text":"考え中","thought":true},
			{"text":"おはようなのだ！"}
		]}}]}`))
	}))
	defer server.Close()

	client := &GeminiClient{Project: "sandbox", Model: "gemini-3.1-flash-lite", ThinkingLevel: "MINIMAL", Endpoint: server.URL, HTTPClient: server.Client()}
	reply, err := client.Chat(context.Background(), []Message{
		{Role: RoleSystem, Content: "キャラ設定"},
		{Role: RoleUser, Content: "おはよう"},
	})
	assert.NoError(t, err)
	assert.Equal(t, "おはようなのだ！", reply)

	assert.Equal(t, "/v1/projects/sandbox/locations/global/publishers/google/models/gemini-3.1-flash-lite:generateContent", gotPath)
	assert.Equal(t, "MINIMAL", gotBody["generationConfig"].(map[string]any)["thinkingConfig"].(map[string]any)["thinkingLevel"])
	assert.NotNil(t, gotBody["systemInstruction"])
}

func TestGeminiClientChatError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":{"message":"Thinking level is unsupported"}}`))
	}))
	defer server.Close()

	client := &GeminiClient{Project: "sandbox", Model: "m", Endpoint: server.URL, HTTPClient: server.Client()}
	_, err := client.Chat(context.Background(), []Message{{Role: RoleUser, Content: "x"}})
	assert.ErrorContains(t, err, "Thinking level is unsupported")
}

func TestGeminiClientChatWithTools(t *testing.T) {
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(b, &gotBody)
		_, _ = w.Write([]byte(`{"candidates":[{"content":{"role":"model","parts":[
			{"text":"ちょっと見てみますね。"},
			{"functionCall":{"name":"calendar.today","args":{}},"thoughtSignature":"sig-1"}
		]}}]}`))
	}))
	defer server.Close()

	client := &GeminiClient{Project: "sandbox", Model: "gemini-3.1-flash-lite", Endpoint: server.URL, HTTPClient: server.Client()}
	result, err := client.ChatWithTools(context.Background(), []Message{
		{Role: RoleSystem, Content: "キャラ設定"},
		{Role: RoleUser, Content: "今日の予定は？"},
	}, []Tool{{Name: "calendar.today", Description: "今日の予定を読む"}})
	assert.NoError(t, err)
	assert.Equal(t, "ちょっと見てみますね。", result.Text)
	assert.Equal(t, []ToolCall{{ID: "call_1", Name: "calendar.today", Signature: "sig-1"}}, []ToolCall{{
		ID: result.ToolCalls[0].ID, Name: result.ToolCalls[0].Name, Signature: result.ToolCalls[0].Signature,
	}})

	// 道具の定義を送っている
	declarations := gotBody["tools"].([]any)[0].(map[string]any)["functionDeclarations"].([]any)
	assert.Equal(t, "calendar.today", declarations[0].(map[string]any)["name"])
}

func TestToGeminiContentsWithToolCalls(t *testing.T) {
	// 道具の呼び出しは署名つきの functionCall、結果は functionResponse として送り返す
	_, contents := toGeminiContents([]Message{
		{Role: RoleSystem, Content: "キャラ設定"},
		{Role: RoleUser, Content: "今日の予定は？"},
		{Role: RoleAssistant, Content: "ちょっと見てみますね。", ToolCalls: []ToolCall{{ID: "call_1", Name: "calendar.today", Signature: "sig-1"}}},
		{Role: RoleTool, ToolCallID: "call_1", Content: `[{"title":"歯医者","start":"10:00"}]`},
		{Role: RoleSystem, Content: "Reply in English."},
	})

	assert.Len(t, contents, 3)
	assert.Equal(t, "user", contents[0].Role)

	model := contents[1]
	assert.Equal(t, "model", model.Role)
	assert.Equal(t, "ちょっと見てみますね。", model.Parts[0].Text)
	assert.Equal(t, "calendar.today", model.Parts[1].FunctionCall.Name)
	assert.Equal(t, "sig-1", model.Parts[1].ThoughtSignature)

	// 道具の結果と、そのあとの system は user にまとまる
	user := contents[2]
	assert.Equal(t, "user", user.Role)
	assert.Equal(t, "calendar.today", user.Parts[0].FunctionResponse.Name)
	assert.Equal(t, `[{"title":"歯医者","start":"10:00"}]`, user.Parts[0].FunctionResponse.Response["content"])
	assert.Equal(t, "Reply in English.", user.Parts[1].Text)
}
