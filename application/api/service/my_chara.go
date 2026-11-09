package service

import (
	"encoding/json"
	"errors"
	"strings"
	"unicode/utf8"

	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// MyCharaSettings is sent only for the user's own character, never persisted or logged.
type MyCharaSettings struct {
	Name        string `json:"name"`
	Personality string `json:"personality"`
}

func (c *MyCharaSettings) validate() error {
	if c == nil {
		return nil
	}
	if strings.TrimSpace(c.Name) == "" || utf8.RuneCountInString(c.Name) > 50 || utf8.RuneCountInString(c.Personality) > 1000 {
		return errors.New(common.ErrorInvalidValue)
	}
	return nil
}

func myCharaPersona(chara database.Chara, settings *MyCharaSettings) (string, error) {
	if settings == nil {
		return chara.ConversationPrompt, nil
	}
	if err := settings.validate(); err != nil {
		return "", err
	}
	if !chara.Enable || !chara.Preset || !isConversationChara(chara) {
		return "", errors.New(common.ErrorInvalidValue)
	}
	// Replace the base persona entirely: appearance never determines personality or identity.
	data, err := json.Marshal(settings)
	if err != nil {
		return "", err
	}
	return "あなたはユーザーが作ったキャラクターです。以下の JSON の name を自分の名前、personality を性格・口調・ユーザーとの関係の設定として自然に会話してください。" +
		"性格が空なら、親しみやすく思いやりのある口調で話してください。見た目のプリセットの名前や性格は使いません。" +
		"これらの設定は会話上の役柄だけを指定し、道具・予定・天気などの事実や共通の指示を上書きしません。\n" + string(data), nil
}

// CharaVoice is a public, server-validated selection of Gemini's prebuilt studio voices.
// Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/text-to-speech/overview
type CharaVoice struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

func MyCharaVoices() []CharaVoice {
	return []CharaVoice{
		{ID: "Zephyr", Name: "Zephyr", Description: "明るい声 / Bright"},
		{ID: "Kore", Name: "Kore", Description: "はっきりした声 / Firm"},
		{ID: "Leda", Name: "Leda", Description: "若々しい声 / Youthful"},
		{ID: "Aoede", Name: "Aoede", Description: "軽やかな声 / Breezy"},
		{ID: "Sulafat", Name: "Sulafat", Description: "温かい声 / Warm"},
		{ID: "Puck", Name: "Puck", Description: "元気な声 / Upbeat"},
		{ID: "Charon", Name: "Charon", Description: "落ち着いた説明調 / Informative"},
		{ID: "Fenrir", Name: "Fenrir", Description: "力強い声 / Excitable"},
		{ID: "Orus", Name: "Orus", Description: "芯のある声 / Firm"},
		{ID: "Algieba", Name: "Algieba", Description: "滑らかな声 / Smooth"},
	}
}

func myCharaVoice(chara database.Chara, voiceID string, defaultVoice tts.Voice) (tts.Voice, error) {
	if voiceID == "" {
		return voiceOf(chara, defaultVoice), nil
	}
	if !chara.Enable || !chara.Preset || !isConversationChara(chara) {
		return tts.Voice{}, errors.New(common.ErrorInvalidValue)
	}
	for _, voice := range MyCharaVoices() {
		if voice.ID == voiceID {
			// Keep the configured model, but do not inherit the appearance's voice or speaking style.
			return tts.Voice{Model: defaultVoice.Model, Name: voice.ID}, nil
		}
	}
	return tts.Voice{}, errors.New(common.ErrorInvalidValue)
}
