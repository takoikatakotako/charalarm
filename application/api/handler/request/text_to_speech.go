package request

// TextToSpeech は /tts のリクエストボディ。
// 通常のキャラの声はサーバで決める。プリセットでは公開一覧の声を選べる。
type TextToSpeech struct {
	CharaID string `json:"charaID"`
	Text    string `json:"text"`
	// VoiceID can select a public catalog voice only for a preset character.
	VoiceID string `json:"voiceID"`
}
