package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestConvertToCharaConversation(t *testing.T) {
	t.Run("人格プロンプトがないキャラは会話しない", func(t *testing.T) {
		assert.Nil(t, convertToCharaConversation(database.Chara{CharaID: "com.charalarm.yui"}))
	})

	t.Run("未設定の項目は既定を使う (声は VOICEVOX)", func(t *testing.T) {
		conversation := convertToCharaConversation(database.Chara{ConversationPrompt: "ずんだもん", VoicevoxStyleID: 3})
		assert.Equal(t, &output.CharaConversation{
			VoiceProvider:       database.ConversationTypeVoicevox,
			VoicevoxStyleID:     3,
			Languages:           []string{database.LanguageJapanese},
			OpeningPrompt:       defaultCallOpeningPrompt,
			EndingPrompt:        defaultCallEndingPrompt,
			NoInputEndingPrompt: defaultCallNoInputEndingPrompt,
		}, conversation)
	})

	t.Run("古い voiceProvider のキャラは、その声で会話する", func(t *testing.T) {
		conversation := convertToCharaConversation(database.Chara{ConversationPrompt: "結衣", VoiceProvider: "gemini"})
		assert.Equal(t, database.ConversationTypeGemini, conversation.VoiceProvider)
	})

	t.Run("アラーム専用のキャラは、人格プロンプトがあっても会話しない", func(t *testing.T) {
		assert.Nil(t, convertToCharaConversation(database.Chara{
			ConversationType:   database.ConversationTypeNone,
			ConversationPrompt: "結衣",
			VoiceProvider:      "gemini",
		}))
	})

	t.Run("キャラごとの設定で上書きする", func(t *testing.T) {
		conversation := convertToCharaConversation(database.Chara{
			ConversationPrompt:      "新キャラ",
			ConversationType:        database.ConversationTypeGemini,
			CallOpeningPrompt:       "最初",
			CallEndingPrompt:        "終わり",
			CallNoInputEndingPrompt: "無音",
		})
		assert.Equal(t, database.ConversationTypeGemini, conversation.VoiceProvider)
		assert.Equal(t, "最初", conversation.OpeningPrompt)
		assert.Equal(t, "終わり", conversation.EndingPrompt)
		assert.Equal(t, "無音", conversation.NoInputEndingPrompt)
	})
}

func TestVoiceOf(t *testing.T) {
	defaultVoice := tts.Voice{Model: "gemini-3.8-flash-tts", Name: "ja-jp-advisor-5"}

	assert.Equal(t, defaultVoice, voiceOf(database.Chara{}, defaultVoice))
	assert.Equal(t,
		tts.Voice{Model: "gemini-3.8-flash-tts", Name: "voice_123", Style: "明るく"},
		voiceOf(database.Chara{GeminiVoice: "voice_123", GeminiVoiceStyle: "明るく"}, defaultVoice))
}
