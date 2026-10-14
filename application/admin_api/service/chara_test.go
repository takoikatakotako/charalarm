package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestValidateCharaSettings(t *testing.T) {
	valid := output.CharaSettings{
		Name:             "結衣",
		AppearanceType:   database.AppearanceTypeIllustration,
		ConversationType: database.ConversationTypeNone,
	}

	t.Run("アラーム専用の立ち絵のキャラ", func(t *testing.T) {
		assert.NoError(t, validateCharaSettings(valid))
	})

	t.Run("名前は必須", func(t *testing.T) {
		s := valid
		s.Name = ""
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)
	})

	t.Run("知らないタイプは受け付けない", func(t *testing.T) {
		s := valid
		s.AppearanceType = "live2d"
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)

		s = valid
		s.ConversationType = "openai"
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)
	})

	t.Run("会話するキャラには人格プロンプトと言語が要る", func(t *testing.T) {
		s := valid
		s.ConversationType = database.ConversationTypeGemini
		s.ConversationLanguages = []string{"ja", "en"}
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)

		s.ConversationPrompt = "新キャラ"
		assert.NoError(t, validateCharaSettings(s))

		s.ConversationLanguages = nil
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)

		s.ConversationLanguages = []string{"fr"}
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)
	})

	t.Run("VOICEVOX は日本語だけ", func(t *testing.T) {
		s := valid
		s.ConversationType = database.ConversationTypeVoicevox
		s.ConversationPrompt = "ずんだもん"
		s.ConversationLanguages = []string{"ja"}
		assert.NoError(t, validateCharaSettings(s))

		s.ConversationLanguages = []string{"ja", "en"}
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)
	})

	t.Run("VRM のキャラは、有効にするときだけ VRM のファイルが要る", func(t *testing.T) {
		s := valid
		s.AppearanceType = database.AppearanceTypeVRM
		assert.NoError(t, validateCharaSettings(s))

		s.Enable = true
		assert.ErrorIs(t, validateCharaSettings(s), ErrInvalidChara)

		s.VRMFileName = "model.vrm"
		assert.NoError(t, validateCharaSettings(s))
	})
}

func TestApplyCharaSettings(t *testing.T) {
	chara := database.Chara{
		CharaID:       "com.charalarm.yui",
		VoiceProvider: "gemini",
		Calls:         []database.CharaCall{{Message: "おはよう", VoiceFileName: "call-01.caf"}},
	}
	applyCharaSettings(&chara, output.CharaSettings{
		Name:             "結衣",
		AppearanceType:   database.AppearanceTypeIllustration,
		ConversationType: database.ConversationTypeNone,
	})

	// 会話のタイプを書き、古い voiceProvider は消す
	assert.Equal(t, database.ConversationTypeNone, chara.ConversationTypeOf())
	assert.Equal(t, "", chara.VoiceProvider)
	// calls は管理画面のこの項目では変えない
	assert.Len(t, chara.Calls, 1)
}

func TestResourceContentType(t *testing.T) {
	contentType, err := resourceContentType("model.VRM")
	assert.NoError(t, err)
	assert.Equal(t, "model/gltf-binary", contentType)

	contentType, err = resourceContentType("call-01.caf")
	assert.NoError(t, err)
	assert.Equal(t, "audio/x-caf", contentType)

	for _, fileName := range []string{"../yui/normal.png", "a b.png", ".hidden.png", "script.js", ""} {
		_, err := resourceContentType(fileName)
		assert.ErrorIs(t, err, ErrInvalidChara, fileName)
	}
}

func TestValidateAssets(t *testing.T) {
	files := []infrastructure.ResourceFile{{FileName: "normal.png"}, {FileName: "tap-01.caf"}, {FileName: "call-01.caf"}}

	assert.NoError(t, validateAssets(
		map[string]output.CharaExpression{"normal": {ImageFileNames: []string{"normal.png"}, VoiceFileNames: []string{"tap-01.caf"}}},
		[]output.CharaCall{{Message: "おはよう", VoiceFileName: "call-01.caf"}},
		files,
	))

	// アップロードしていないファイルは指せない
	assert.ErrorIs(t, validateAssets(
		map[string]output.CharaExpression{"smile": {ImageFileNames: []string{"smile.png"}}},
		nil, files,
	), ErrInvalidChara)
	assert.ErrorIs(t, validateAssets(nil, []output.CharaCall{{Message: "おはよう"}}, files), ErrInvalidChara)
}
