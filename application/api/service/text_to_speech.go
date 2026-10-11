package service

import (
	"context"
	"errors"
	"log"
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
	// Voice は PoC の間は全キャラ共通。キャラごとの声はキャラ情報で持つ予定。
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
	if charaID == "" || text == "" || utf8.RuneCountInString(text) > ttsMaxTextLength {
		return tts.Audio{}, errors.New(common.ErrorInvalidValue)
	}

	// ユーザー認証 (合成の踏み台化を防ぐため、実在ユーザーのみ許可)
	user, err := s.AWS.GetUser(userID)
	if err != nil {
		return tts.Audio{}, err
	}
	if user.UserID != userID || user.AuthToken != authToken {
		return tts.Audio{}, errors.New(common.ErrorAuthenticationFailure)
	}

	start := time.Now()
	audio, err := s.Client.Synthesize(ctx, text, s.Voice)
	if err != nil {
		return tts.Audio{}, err
	}
	log.Printf("tts: chara=%s voice=%s model=%s chars=%d audio=%.2fs elapsed=%dms",
		charaID, s.Voice.Name, s.Voice.Model, utf8.RuneCountInString(text), audio.Seconds, time.Since(start).Milliseconds())
	return audio, nil
}
