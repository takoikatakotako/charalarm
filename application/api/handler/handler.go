package handler

import (
	"github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/service/input"
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
