package queue

import "github.com/takoikatakotako/charalarm/infrastructure/database"

type IOSVoIPPushAlarmInfoSQSMessage struct {
	AlarmID        string `json:"alarmID"`
	UserID         string `json:"userID"`
	SNSEndpointArn string `json:"snsEndpointArn"`
	CharaID        string `json:"charaID"`
	CharaName      string `json:"charaName"`
	VoiceFileURL   string `json:"voiceFileURL"`
	// Call はアラームの電話（AI 会話）の設定。nil ならアプリ共通の設定
	Call *database.AlarmCall `json:"call,omitempty"`
}
