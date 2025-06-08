package queue

type IOSVoIPPushAlarmInfoSQSMessage struct {
	AlarmID        string `json:"alarmID"`
	UserID         string `json:"userID"`
	SNSEndpointArn string `json:"snsEndpointArn"`
	CharaID        string `json:"charaID"`
	CharaName      string `json:"charaName"`
	VoiceFileURL   string `json:"voiceFileURL"`
}
