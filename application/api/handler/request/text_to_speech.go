package request

// TextToSpeech は /tts のリクエストボディ。
// 声は charaID からサーバ側で決めるので、端末からは指定しない。
type TextToSpeech struct {
	CharaID string `json:"charaID"`
	Text    string `json:"text"`
}
