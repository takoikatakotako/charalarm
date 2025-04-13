package service

import (
	"github.com/takoikatakotako/charalarm/api/service/input"
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func convertToDatabaseAlarm(alarm input.Alarm, target string) database.Alarm {
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

func convertToAlarmOutput(alarm database.Alarm) output.Alarm {
	// UTCのdatabase.Alarmを時差のあるresponse.Alarmに変換する
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
	diff := (float32(alarm.Hour) + float32(alarm.Minute)/60.0) + alarm.TimeDifference
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
		alarmSaturday = alarm.Friday
		alarmFriday = alarm.Thursday
		alarmThursday = alarm.Wednesday
		alarmWednesday = alarm.Tuesday
		alarmTuesday = alarm.Monday
		alarmMonday = alarm.Sunday
		alarmSunday = alarm.Saturday
	}

	return output.Alarm{
		AlarmID:        alarm.AlarmID,
		UserID:         alarm.UserID,
		Type:           alarm.Type,
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
}

func convertToCharaOutputs(databaseCharas []database.Chara, baseURL string) []output.Chara {
	charaOutputs := make([]output.Chara, 0)
	for i := 0; i < len(databaseCharas); i++ {
		charaOutput := convertToCharaOutput(databaseCharas[i], baseURL)
		charaOutputs = append(charaOutputs, charaOutput)
	}
	return charaOutputs
}

func convertToCharaOutput(databaseChara database.Chara, baseURL string) output.Chara {
	return output.Chara{
		CharaID:     databaseChara.CharaID,
		Enable:      databaseChara.Enable,
		Name:        databaseChara.Name,
		CreatedAt:   databaseChara.CreatedAt,
		UpdatedAt:   databaseChara.UpdatedAd,
		Description: databaseChara.Description,
		Profiles:    databaseCharaProfileListToResponseCharaProfileList(databaseChara.Profiles),
		Resources:   databaseCharaToResponseCharaResourceList(databaseChara, baseURL),
		Expression:  databaseCharaExpressionMapToResponseCharaExpressionMap(databaseChara.Expressions, baseURL, databaseChara.CharaID),
		Calls:       databaseCharaCallListToResponseCharaCallList(databaseChara.Calls, baseURL, databaseChara.CharaID),
	}
}

func databaseCharaProfileListToResponseCharaProfileList(databaseCharaProfiles []database.CharaProfile) []output.CharaProfile {
	responseCharaProfileList := make([]output.CharaProfile, 0)
	for i := 0; i < len(databaseCharaProfiles); i++ {
		responseCharaProfile := databaseCharaProfileToResponseCharaProfile(databaseCharaProfiles[i])
		responseCharaProfileList = append(responseCharaProfileList, responseCharaProfile)
	}
	return responseCharaProfileList
}

func databaseCharaProfileToResponseCharaProfile(databaseCharaProfile database.CharaProfile) output.CharaProfile {
	return output.CharaProfile{
		Title: databaseCharaProfile.Title,
		Name:  databaseCharaProfile.Name,
		URL:   databaseCharaProfile.URL,
	}
}

func databaseCharaToResponseCharaResourceList(databaseChara database.Chara, resourceBaseURL string) []output.CharaResource {
	// response2.CharaResourcesを作成
	responseCharaResources := make([]output.CharaResource, 0)

	// expressionsのリソースを生成
	for _, databaseCharaExpression := range databaseChara.Expressions {
		for _, imageFileName := range databaseCharaExpression.ImageFileNames {
			responseCharaResources = append(responseCharaResources, output.CharaResource{
				FileURL: createFileURL(resourceBaseURL, databaseChara.CharaID, imageFileName),
			})
		}

		for _, voiceFileName := range databaseCharaExpression.VoiceFileNames {
			responseCharaResources = append(responseCharaResources, output.CharaResource{
				FileURL: createFileURL(resourceBaseURL, databaseChara.CharaID, voiceFileName),
			})
		}
	}

	// callsのリソースを生成
	for _, databaseCharaCall := range databaseChara.Calls {
		responseCharaResources = append(responseCharaResources, output.CharaResource{
			FileURL: createFileURL(resourceBaseURL, databaseChara.CharaID, databaseCharaCall.VoiceFileName),
		})
	}

	// TODO: responseCharaResources の中から重複要素を削除
	return responseCharaResources
}

func databaseCharaExpressionMapToResponseCharaExpressionMap(databaseCharaExpressionMap map[string]database.CharaExpression, baseURL string, charaID string) map[string]output.CharaExpression {
	responseCharaExpressionMap := map[string]output.CharaExpression{}
	for key, databaseCharaExpression := range databaseCharaExpressionMap {
		// 画像とボイスにBase URLを追加する
		responseImages := make([]string, 0)
		for _, imageFileName := range databaseCharaExpression.ImageFileNames {
			responseImages = append(responseImages, createFileURL(baseURL, charaID, imageFileName))
		}
		responseVoices := make([]string, 0)
		for _, voiceFileName := range databaseCharaExpression.VoiceFileNames {
			responseVoices = append(responseVoices, createFileURL(baseURL, charaID, voiceFileName))
		}

		responseCharaExpression := output.CharaExpression{
			ImageFileURLs: responseImages,
			VoiceFileURLs: responseVoices,
		}
		responseCharaExpressionMap[key] = responseCharaExpression
	}
	return responseCharaExpressionMap
}

func databaseCharaCallListToResponseCharaCallList(databaseCharaCallList []database.CharaCall, baseURL string, charaID string) []output.CharaCall {
	responseCharaCallList := make([]output.CharaCall, 0)
	for i := 0; i < len(databaseCharaCallList); i++ {
		responseCharaCall := databaseCharaCallToResponseCharaCall(databaseCharaCallList[i], baseURL, charaID)
		responseCharaCallList = append(responseCharaCallList, responseCharaCall)
	}
	return responseCharaCallList
}

func databaseCharaCallToResponseCharaCall(databaseCharaCall database.CharaCall, baseURL string, charaID string) output.CharaCall {
	return output.CharaCall{
		Message:       databaseCharaCall.Message,
		VoiceFileName: databaseCharaCall.VoiceFileName,
		VoiceFileURL:  createFileURL(baseURL, charaID, databaseCharaCall.VoiceFileName),
	}
}

func createFileURL(resourceBaseURL string, charaID string, fileName string) string {
	return resourceBaseURL + "/" + charaID + "/" + fileName
}
