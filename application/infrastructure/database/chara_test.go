package database

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestConversationLanguages(t *testing.T) {
	// 未設定なら日本語だけ
	assert.Equal(t, []string{LanguageJapanese}, Chara{}.ConversationLanguagesOf())
	assert.Equal(t, LanguageJapanese, Chara{}.ConversationLanguageFor(LanguageEnglish))

	shiori := Chara{ConversationLanguages: []string{LanguageJapanese, LanguageEnglish}}
	assert.Equal(t, LanguageEnglish, shiori.ConversationLanguageFor(LanguageEnglish))
	assert.Equal(t, LanguageJapanese, shiori.ConversationLanguageFor(""))
	assert.Equal(t, LanguageJapanese, shiori.ConversationLanguageFor("fr"))
}

func TestCharaTypeOf(t *testing.T) {
	t.Run("見た目は未設定なら立ち絵", func(t *testing.T) {
		assert.Equal(t, AppearanceTypeIllustration, Chara{}.AppearanceTypeOf())
		assert.Equal(t, AppearanceTypeVRM, Chara{AppearanceType: AppearanceTypeVRM}.AppearanceTypeOf())
	})

	t.Run("会話のタイプは未設定なら古い項目から導く", func(t *testing.T) {
		// 結衣・紅葉 (人格プロンプトなし)
		assert.Equal(t, ConversationTypeNone, Chara{}.ConversationTypeOf())
		// ずんだもん (voiceProvider なし)
		assert.Equal(t, ConversationTypeVoicevox, Chara{ConversationPrompt: "ずんだもん"}.ConversationTypeOf())
		// development の結衣 (voiceProvider=gemini)
		assert.Equal(t, ConversationTypeGemini, Chara{ConversationPrompt: "結衣", VoiceProvider: "gemini"}.ConversationTypeOf())
	})

	t.Run("会話のタイプが書いてあれば、それを使う", func(t *testing.T) {
		assert.Equal(t, ConversationTypeNone, Chara{
			ConversationType:   ConversationTypeNone,
			ConversationPrompt: "結衣",
			VoiceProvider:      "gemini",
		}.ConversationTypeOf())
	})
}
