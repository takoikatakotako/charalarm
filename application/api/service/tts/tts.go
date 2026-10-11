package tts

import "context"

// Voice は合成に使う声の設定。キャラごとにサーバ側で決める。
type Voice struct {
	// Model は合成モデル (例: gemini-3.8-flash-tts)。
	Model string
	// Name は声の名前 (例: ja-jp-advisor-5)。複製した声なら voice_... の ID。
	Name string
	// Style は話し方の指示 (省略可)。
	Style string
}

// Audio は合成した音声。
type Audio struct {
	// WAV は 16bit mono の WAV。
	WAV []byte
	// Seconds は音声の長さ (秒)。
	Seconds float64
}

// Client はプロバイダ非依存の音声合成クライアント。
type Client interface {
	Synthesize(ctx context.Context, text string, voice Voice) (Audio, error)
}
