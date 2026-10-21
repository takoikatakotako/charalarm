package service

import (
	"context"
	"errors"
	"log/slog"
	"time"
	"unicode/utf8"

	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// 1回に合成する文字数の上限。端末は文ごとに区切って呼ぶ前提。
const ttsMaxTextLength = 200

// ErrTTSNotConfigured は音声合成が設定されていない環境で返す。
var ErrTTSNotConfigured = errors.New("tts is not configured")

// TextToSpeech はキャラの発話を音声にするサービス。
type TextToSpeech struct {
	AWS    infrastructure.AWS
	Client tts.Client
	// Voice は既定の声。キャラ情報 (geminiVoice / geminiVoiceStyle) で上書きする。
	Voice tts.Voice
}

// Synthesize はユーザーを認証したうえで text を合成する。
// 発話テキストはログに出さない。
func (s *TextToSpeech) Synthesize(ctx context.Context, userID string, authToken string, charaID string, text string) (tts.Audio, error) {
	if s.Client == nil {
		return tts.Audio{}, ErrTTSNotConfigured
	}

	// バリデーション
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return tts.Audio{}, errors.New(common.ErrorInvalidValue)
	}
	if charaID == "" || text == "" {
		return tts.Audio{}, invalidValue("tts: chara or text is empty", slog.String("chara", charaID))
	}
	if length := utf8.RuneCountInString(text); length > ttsMaxTextLength {
		return tts.Audio{}, invalidValue("tts: text is too long",
			slog.String("chara", charaID), slog.Int("chars", length), slog.Int("max", ttsMaxTextLength))
	}

	// ユーザー認証 (合成の踏み台化を防ぐため、実在ユーザーのみ許可)
	user, err := s.AWS.GetUser(userID)
	if err != nil {
		return tts.Audio{}, err
	}
	if user.UserID != userID || user.AuthToken != authToken {
		return tts.Audio{}, errors.New(common.ErrorAuthenticationFailure)
	}

	// Gemini TTS で話すキャラだけ合成する (VOICEVOX のキャラは端末内で合成する)
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return tts.Audio{}, invalidValue("tts: chara not found", slog.String("chara", charaID), slog.String("error", err.Error()))
	}
	if !isConversationChara(chara) || chara.ConversationTypeOf() != database.ConversationTypeGemini {
		return tts.Audio{}, invalidValue("tts: chara does not use gemini tts", slog.String("chara", charaID))
	}
	voice := voiceOf(chara, s.Voice)

	start := time.Now()
	audio, err := s.Client.Synthesize(ctx, text, voice)
	if err != nil {
		return tts.Audio{}, err
	}
	slog.Info("tts",
		slog.String("chara", charaID), slog.String("voice", voice.Name), slog.String("model", voice.Model),
		slog.Int("chars", utf8.RuneCountInString(text)), slog.Float64("audio_seconds", audio.Seconds),
		slog.Int64("elapsed_ms", time.Since(start).Milliseconds()))
	return audio, nil
}

// voiceOf はキャラの声を返す。キャラに設定がなければ既定の声を使う。
func voiceOf(chara database.Chara, defaultVoice tts.Voice) tts.Voice {
	voice := defaultVoice
	if chara.GeminiVoice != "" {
		voice.Name = chara.GeminiVoice
	}
	if chara.GeminiVoiceStyle != "" {
		voice.Style = chara.GeminiVoiceStyle
	}
	return voice
}
