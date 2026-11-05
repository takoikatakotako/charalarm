package input

import "github.com/takoikatakotako/charalarm/infrastructure/database"

type Alarm struct {
	AlarmID string
	UserID  string

	// IOS_PUSH_NOTIFICATION, IOS_VOIP_PUSH_NOTIFICATION
	Type           string
	Enable         bool
	Name           string
	Hour           int
	Minute         int
	TimeDifference float32

	// Chara Info
	CharaID       string
	CharaName     string
	VoiceFileName string

	// Weekday
	Sunday    bool
	Monday    bool
	Tuesday   bool
	Wednesday bool
	Thursday  bool
	Friday    bool
	Saturday  bool

	// Call はアラームの電話（AI 会話）の設定。nil ならアプリ共通の設定
	Call *database.AlarmCall
}
