package database

import "fmt"

const (
	AlarmTableName           = "alarm-table"
	AlarmTableColumnAlarmID  = "alarmID"
	AlarmTableColumnUserID   = "userID"
	AlarmTableColumnTime     = "time"
	AlarmTableIndexAlarmTime = "alarm-time-index"
	AlarmTableIndexUserID    = "user-id-index"
)

type Alarm struct {
	AlarmID string `dynamodbav:"alarmID"`
	UserID  string `dynamodbav:"userID"`

	// Target Info
	Type   string `dynamodbav:"type"` // IOS_PUSH_NOTIFICATION, IOS_VOIP_PUSH_NOTIFICATION
	Target string `dynamodbav:"target"`

	// AlarmInfo
	Enable         bool    `dynamodbav:"enable"`
	Name           string  `dynamodbav:"name"`
	Hour           int     `dynamodbav:"hour"`
	Minute         int     `dynamodbav:"minute"`
	Time           string  `dynamodbav:"time"`
	TimeDifference float32 `dynamodbav:"timeDifference"`

	// Chara Info
	CharaID       string `dynamodbav:"charaID"`
	CharaName     string `dynamodbav:"charaName"`
	VoiceFileName string `dynamodbav:"voiceFileName"`

	// Weekday
	Sunday    bool `dynamodbav:"sunday"`
	Monday    bool `dynamodbav:"monday"`
	Tuesday   bool `dynamodbav:"tuesday"`
	Wednesday bool `dynamodbav:"wednesday"`
	Thursday  bool `dynamodbav:"thursday"`
	Friday    bool `dynamodbav:"friday"`
	Saturday  bool `dynamodbav:"saturday"`
}

func (a *Alarm) SetAlarmTime() {
	a.Time = fmt.Sprintf("%02d-%02d", a.Hour, a.Minute)
}
