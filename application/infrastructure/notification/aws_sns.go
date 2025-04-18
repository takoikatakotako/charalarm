package notification

type IOSVoIPPushSNSMessage struct {
	CharaID      string `json:"charaID"`
	CharaName    string `json:"charaName"`
	VoiceFileURL string `json:"voiceFileURL"`
}
