package database

import (
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm/common"
)

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

func (a *Alarm) Validate() error {
	// AlarmID
	if !IsValidUUID(a.AlarmID) {
		return errors.New(common.ErrorInvalidValue + ": AlarmID")
	}

	// UserID
	if !IsValidUUID(a.UserID) {
		return errors.New(common.ErrorInvalidValue + ": UserID")
	}

	// Type
	// IOS_PUSH_NOTIFICATION, IOS_VOIP_PUSH_NOTIFICATION
	if a.Type == "IOS_PUSH_NOTIFICATION" || a.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": Type")
	}

	// Target
	if a.Target == "" {
		return errors.New(common.ErrorInvalidValue + ": Target")
	}

	// Enable

	// Name
	if a.Name == "" {
		return errors.New(common.ErrorInvalidValue + ": Name")
	}

	// Hour
	if 0 <= a.Hour && a.Hour <= 23 {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": Hour")
	}

	// Minute
	if 0 <= a.Minute && a.Minute <= 59 {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": Minute")
	}

	// Time
	if a.Time == fmt.Sprintf("%02d-%02d", a.Hour, a.Minute) {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": Time")
	}

	// TimeDifference
	if -24 < a.TimeDifference && a.TimeDifference < 24 {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": TimeDifference")
	}

	// CharaID

	// CharaName

	// VoiceFileName

	// Sunday

	// Monday

	// Tuesday

	// Wednesday

	// Thursday

	// Friday

	// Saturday

	return nil
}
