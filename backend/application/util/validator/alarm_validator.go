package validator

import (
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/util/message"
)

func ValidateAlarm(alarm database.Alarm) error {
	// AlarmID
	if !IsValidUUID(alarm.AlarmID) {
		return errors.New(message.ErrorInvalidValue + ": AlarmID")
	}

	// UserID
	if !IsValidUUID(alarm.UserID) {
		return errors.New(message.ErrorInvalidValue + ": UserID")
	}

	// Type
	// IOS_PUSH_NOTIFICATION, IOS_VOIP_PUSH_NOTIFICATION
	if alarm.Type == "IOS_PUSH_NOTIFICATION" || alarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		// Nothing
	} else {
		return errors.New(message.ErrorInvalidValue + ": Type")
	}

	// Target
	if alarm.Target == "" {
		return errors.New(message.ErrorInvalidValue + ": Target")
	}

	// Enable

	// Name
	if alarm.Name == "" {
		return errors.New(message.ErrorInvalidValue + ": Name")
	}

	// Hour
	if 0 <= alarm.Hour && alarm.Hour <= 23 {
		// Nothing
	} else {
		return errors.New(message.ErrorInvalidValue + ": Hour")
	}

	// Minute
	if 0 <= alarm.Minute && alarm.Minute <= 59 {
		// Nothing
	} else {
		return errors.New(message.ErrorInvalidValue + ": Minute")
	}

	// Time
	if alarm.Time == fmt.Sprintf("%02d-%02d", alarm.Hour, alarm.Minute) {
		// Nothing
	} else {
		return errors.New(message.ErrorInvalidValue + ": Time")
	}

	// TimeDifference
	if -24 < alarm.TimeDifference && alarm.TimeDifference < 24 {
		// Nothing
	} else {
		return errors.New(message.ErrorInvalidValue + ": TimeDifference")
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
