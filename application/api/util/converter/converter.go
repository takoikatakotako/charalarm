package converter

import (
	"github.com/takoikatakotako/charalarm/api/handler/request"
	response2 "github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func DatabaseUserToResponseUserInfo(user database.User) response2.UserInfoResponse {
	return response2.UserInfoResponse{
		UserID:          user.UserID,
		AuthToken:       maskAuthToken(user.AuthToken),
		Platform:        user.Platform,
		PremiumPlan:     user.PremiumPlan,
		IOSPlatformInfo: DatabaseIOSPlatformInfoToResponseIOSPlatformInfoResponse(user.IOSPlatformInfo),
	}
}

func DatabaseIOSPlatformInfoToResponseIOSPlatformInfoResponse(iOSPlatformInfo database.UserIOSPlatformInfo) response2.IOSPlatformInfoResponse {
	return response2.IOSPlatformInfoResponse{
		PushToken:                iOSPlatformInfo.PushToken,
		PushTokenSNSEndpoint:     iOSPlatformInfo.PushTokenSNSEndpoint,
		VoIPPushToken:            iOSPlatformInfo.VoIPPushToken,
		VoIPPushTokenSNSEndpoint: iOSPlatformInfo.VoIPPushTokenSNSEndpoint,
	}
}

func RequestAlarmToDatabaseAlarm(alarm request.Alarm, target string) database.Alarm {
	// request.Alarmは時差があるため、UTCのdatabase.Alarmに変換する
	var alarmHour int
	var alarmMinute int
	var alarmSunday bool
	var alarmMonday bool
	var alarmTuesday bool
	var alarmWednesday bool
	var alarmThursday bool
	var alarmFriday bool
	var alarmSaturday bool

	// 時差を計算
	diff := (float32(alarm.Hour) + float32(alarm.Minute)/60.0) - alarm.TimeDifference
	if diff > 24 {
		// tomorrow
		diff -= 24.0
		alarmHour = int(diff)
		alarmMinute = int((diff-float32(alarmHour))*60 + 0.5)
		alarmSunday = alarm.Monday
		alarmMonday = alarm.Tuesday
		alarmTuesday = alarm.Wednesday
		alarmWednesday = alarm.Thursday
		alarmThursday = alarm.Friday
		alarmFriday = alarm.Saturday
		alarmSaturday = alarm.Sunday
	} else if diff >= 0 {
		// today
		alarmHour = int(diff)
		alarmMinute = int((diff-float32(alarmHour))*60 + 0.5)
		alarmSunday = alarm.Sunday
		alarmMonday = alarm.Monday
		alarmTuesday = alarm.Tuesday
		alarmWednesday = alarm.Wednesday
		alarmThursday = alarm.Thursday
		alarmFriday = alarm.Friday
		alarmSaturday = alarm.Saturday
	} else {
		// yesterday
		diff += 24.0
		alarmHour = int(diff)
		alarmMinute = int((diff-float32(alarmHour))*60 + 0.5)
		alarmSunday = alarm.Saturday
		alarmMonday = alarm.Sunday
		alarmTuesday = alarm.Monday
		alarmWednesday = alarm.Tuesday
		alarmThursday = alarm.Wednesday
		alarmFriday = alarm.Thursday
		alarmSaturday = alarm.Friday
	}

	databaseAlarm := database.Alarm{
		AlarmID:        alarm.AlarmID,
		UserID:         alarm.UserID,
		Type:           alarm.Type,
		Target:         target,
		Enable:         alarm.Enable,
		Name:           alarm.Name,
		Hour:           alarmHour,
		Minute:         alarmMinute,
		TimeDifference: alarm.TimeDifference,
		CharaID:        alarm.CharaID,
		CharaName:      alarm.CharaName,
		VoiceFileName:  alarm.VoiceFileName,
		Sunday:         alarmSunday,
		Monday:         alarmMonday,
		Tuesday:        alarmTuesday,
		Wednesday:      alarmWednesday,
		Thursday:       alarmThursday,
		Friday:         alarmFriday,
		Saturday:       alarmSaturday,
	}
	databaseAlarm.SetAlarmTime()
	return databaseAlarm
}

// 文字を*に変換
func maskAuthToken(authToken string) string {
	length := len(authToken)
	var r = ""
	for i := 0; i < length; i++ {
		if i == 0 {
			r += authToken[0:1]
		} else if i == 1 {
			r += authToken[1:2]
		} else {
			r += "*"
		}
	}
	return r
}
