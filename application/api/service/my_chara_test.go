package service

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestMyCharaPersona(t *testing.T) {
	preset := database.Chara{Enable: true, Preset: true, ConversationType: database.ConversationTypeGemini, ConversationPrompt: "プリセット固有の人格"}
	settings := &MyCharaSettings{Name: "みどり", Personality: "丁寧で落ち着いた友達"}
	persona, err := myCharaPersona(preset, settings)
	require.NoError(t, err)
	require.Contains(t, persona, `"name":"みどり"`)
	require.Contains(t, persona, settings.Personality)
	require.NotContains(t, persona, preset.ConversationPrompt)

	// Swapping the appearance cannot change the user's identity or personality.
	another := preset
	another.CharaID = "another-appearance"
	another.ConversationPrompt = "別の性格"
	anotherPersona, err := myCharaPersona(another, settings)
	require.NoError(t, err)
	require.Equal(t, persona, anotherPersona)

	unchanged, err := myCharaPersona(preset, nil)
	require.NoError(t, err)
	require.Equal(t, preset.ConversationPrompt, unchanged)

	for _, invalid := range []database.Chara{
		{Enable: true, ConversationType: "gemini", ConversationPrompt: "通常キャラ"},
		{Preset: true, ConversationType: "gemini", ConversationPrompt: "無効"},
		{Enable: true, Preset: true, ConversationType: "none"},
	} {
		_, err := myCharaPersona(invalid, settings)
		require.Error(t, err)
	}
}

func TestMyCharaInputLimits(t *testing.T) {
	require.NoError(t, (&MyCharaSettings{Name: strings.Repeat("名", 50), Personality: strings.Repeat("あ", 1000)}).validate())
	for _, settings := range []*MyCharaSettings{
		{Name: "   "},
		{Name: strings.Repeat("名", 51)},
		{Name: "名前", Personality: strings.Repeat("あ", 1001)},
	} {
		require.Error(t, settings.validate())
	}
	require.Error(t, validateChatInput(ChatInput{MyChara: &MyCharaSettings{Name: "名前"}}))
}

func TestMyCharaVoice(t *testing.T) {
	defaultVoice := tts.Voice{Model: "configured-model", Name: "default", Style: "default style"}
	preset := database.Chara{Enable: true, Preset: true, ConversationType: "gemini", ConversationPrompt: "base", GeminiVoice: "old-voice", GeminiVoiceStyle: "old-style"}
	for _, choice := range MyCharaVoices() {
		voice, err := myCharaVoice(preset, choice.ID, defaultVoice)
		require.NoError(t, err)
		require.Equal(t, tts.Voice{Model: "configured-model", Name: choice.ID}, voice)
	}
	legacy, err := myCharaVoice(preset, "", defaultVoice)
	require.NoError(t, err)
	require.Equal(t, tts.Voice{Model: "configured-model", Name: "old-voice", Style: "old-style"}, legacy)

	for _, id := range []string{"unknown", "voice_private-custom-voice", "Kore\n"} {
		_, err := myCharaVoice(preset, id, defaultVoice)
		require.Error(t, err)
	}
	preset.Preset = false
	_, err = myCharaVoice(preset, "Kore", defaultVoice)
	require.Error(t, err)
	preset.Preset = true
	preset.Enable = false
	_, err = myCharaVoice(preset, "Kore", defaultVoice)
	require.Error(t, err)
}
