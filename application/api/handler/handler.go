package handler

import (
	"github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service/input"
	"github.com/takoikatakotako/charalarm/api/service/output"
)

func convertToAlarmInput(request request.Alarm) input.Alarm {
	return input.Alarm{
		AlarmID:        request.AlarmID,
		UserID:         request.UserID,
		Type:           request.Type,
		Enable:         request.Enable,
		Name:           request.Name,
		Hour:           request.Hour,
		Minute:         request.Minute,
		TimeDifference: request.TimeDifference,
		CharaID:        request.CharaID,
		CharaName:      request.CharaName,
		VoiceFileName:  request.VoiceFileName,
		Sunday:         request.Sunday,
		Monday:         request.Monday,
		Tuesday:        request.Tuesday,
		Wednesday:      request.Wednesday,
		Thursday:       request.Thursday,
		Friday:         request.Friday,
		Saturday:       request.Saturday,
	}
}

func convertToAlarmResponses(outputs []output.Alarm) []response.Alarm {
	alarmResponses := make([]response.Alarm, 0)
	for i := 0; i < len(outputs); i++ {
		responseAlarm := convertToAlarmResponse(outputs[i])
		alarmResponses = append(alarmResponses, responseAlarm)
	}
	return alarmResponses
}

func convertToAlarmResponse(output output.Alarm) response.Alarm {
	return response.Alarm{
		AlarmID: output.AlarmID,
		UserID:  output.UserID,

		// REMOTE_NOTIFICATION VOIP_NOTIFICATION
		Type:           output.Type,
		Enable:         output.Enable,
		Name:           output.Name,
		Hour:           output.Hour,
		Minute:         output.Minute,
		TimeDifference: output.TimeDifference,

		// Chara Info
		CharaID:       output.CharaID,
		CharaName:     output.CharaName,
		VoiceFileName: output.VoiceFileName,

		// Weekday
		Sunday:    output.Sunday,
		Monday:    output.Monday,
		Tuesday:   output.Tuesday,
		Wednesday: output.Wednesday,
		Thursday:  output.Thursday,
		Friday:    output.Friday,
		Saturday:  output.Saturday,
	}
}
