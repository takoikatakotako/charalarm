package service

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/api/service/llm"
)

func TestValidateChatInput(t *testing.T) {
	user := llm.Message{Role: llm.RoleUser, Content: "おはよう"}

	tests := []struct {
		name    string
		input   ChatInput
		wantErr bool
	}{
		{"最小", ChatInput{Messages: []llm.Message{user}}, false},
		{"system を含む", ChatInput{Messages: []llm.Message{{Role: llm.RoleSystem, Content: "電話に出たところ"}, user}}, false},
		{"記憶と現在時刻つき", ChatInput{
			Memory:   "呼び方はたこさん",
			Context:  &ChatContext{Now: "2026-10-11T07:00:00+09:00", TimeZone: "Asia/Tokyo"},
			Messages: []llm.Message{user},
		}, false},
		{"英語", ChatInput{Language: "en", Messages: []llm.Message{user}}, false},
		{"知らない言語", ChatInput{Language: "fr", Messages: []llm.Message{user}}, true},
		{"メッセージなし", ChatInput{}, true},
		{"メッセージが多すぎる", ChatInput{Messages: repeatMessage(user, chatMaxMessages+1)}, true},
		{"メッセージが上限ちょうど", ChatInput{Messages: repeatMessage(user, chatMaxMessages)}, false},
		{"未知の role", ChatInput{Messages: []llm.Message{{Role: "tool", Content: "x"}}}, true},
		{"空のメッセージ", ChatInput{Messages: []llm.Message{{Role: llm.RoleUser, Content: ""}}}, true},
		{"メッセージが長すぎる", ChatInput{Messages: []llm.Message{{Role: llm.RoleUser, Content: strings.Repeat("あ", chatMaxMessageLength+1)}}}, true},
		{"メッセージが上限ちょうど（文字数で数える）", ChatInput{Messages: []llm.Message{{Role: llm.RoleUser, Content: strings.Repeat("あ", chatMaxMessageLength)}}}, false},
		{"記憶が長すぎる", ChatInput{Memory: strings.Repeat("あ", chatMaxMemoryLength+1), Messages: []llm.Message{user}}, true},
		{"現在時刻の形式が違う", ChatInput{Context: &ChatContext{Now: "2026/10/11 07:00"}, Messages: []llm.Message{user}}, true},
		{"タイムゾーンが長すぎる", ChatInput{
			Context:  &ChatContext{Now: "2026-10-11T07:00:00+09:00", TimeZone: strings.Repeat("a", chatMaxTimeZoneLength+1)},
			Messages: []llm.Message{user},
		}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateChatInput(tt.input)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestBuildChatMessages(t *testing.T) {
	user := llm.Message{Role: llm.RoleUser, Content: "おはよう"}

	t.Run("キャラ設定 → 話し方 → 記憶 → 現在時刻 → 会話の順に並ぶ", func(t *testing.T) {
		messages, err := buildChatMessages("あなたはずんだもんです。", ChatInput{
			Memory:   "呼び方はたこさん",
			Context:  &ChatContext{Now: "2026-10-11T07:05:00+09:00", TimeZone: "Asia/Tokyo"},
			Messages: []llm.Message{user},
		})
		assert.NoError(t, err)
		assert.Len(t, messages, 5)

		assert.Equal(t, llm.Message{Role: llm.RoleSystem, Content: "あなたはずんだもんです。"}, messages[0])

		assert.Equal(t, llm.Message{Role: llm.RoleSystem, Content: chatSpeechInstruction}, messages[1])

		assert.Equal(t, llm.RoleSystem, messages[2].Role)
		assert.Contains(t, messages[2].Content, "<memory>\n呼び方はたこさん\n</memory>")

		assert.Equal(t, llm.Message{Role: llm.RoleSystem, Content: "現在の日時: 2026年10月11日(日) 07:05（Asia/Tokyo）"}, messages[3])

		assert.Equal(t, user, messages[4])
	})

	t.Run("英語のときは、会話のあと (最後) に英語で話す指示を入れる", func(t *testing.T) {
		messages, err := buildChatMessages("あなたは時守しおりです。", ChatInput{Language: "en", Messages: []llm.Message{user}})
		assert.NoError(t, err)
		assert.Equal(t, []llm.Message{
			{Role: llm.RoleSystem, Content: "あなたは時守しおりです。"},
			{Role: llm.RoleSystem, Content: chatSpeechInstruction},
			user,
			{Role: llm.RoleSystem, Content: chatEnglishInstruction},
		}, messages)
	})

	t.Run("省略したものは入れない（話し方の指示は常に入る）", func(t *testing.T) {
		messages, err := buildChatMessages("", ChatInput{Messages: []llm.Message{user}})
		assert.NoError(t, err)
		assert.Equal(t, []llm.Message{{Role: llm.RoleSystem, Content: chatSpeechInstruction}, user}, messages)
	})
}

func TestFormatChatTime(t *testing.T) {
	assert.Equal(t, "2026年10月11日(日) 23:59", formatChatTimeString(t, "2026-10-11T23:59:00+09:00", ""))
	// 端末のオフセットのまま表示する
	assert.Equal(t, "2026年10月10日(土) 14:00（UTC）", formatChatTimeString(t, "2026-10-10T14:00:00Z", "UTC"))
}

func formatChatTimeString(t *testing.T, now string, timeZone string) string {
	t.Helper()
	messages, err := buildChatMessages("", ChatInput{
		Context:  &ChatContext{Now: now, TimeZone: timeZone},
		Messages: []llm.Message{{Role: llm.RoleUser, Content: "x"}},
	})
	assert.NoError(t, err)
	return strings.TrimPrefix(messages[1].Content, "現在の日時: ")
}

func repeatMessage(m llm.Message, n int) []llm.Message {
	messages := make([]llm.Message, n)
	for i := range messages {
		messages[i] = m
	}
	return messages
}
