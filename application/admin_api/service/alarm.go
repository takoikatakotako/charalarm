package service

import (
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type Alarm struct {
	AWS infrastructure.AWS
}

func (a *Alarm) ListByUser(userID string) ([]output.Alarm, error) {
	alarms, err := a.AWS.GetAlarmList(userID)
	if err != nil {
		return nil, err
	}

	out := make([]output.Alarm, 0, len(alarms))
	for _, alarm := range alarms {
		out = append(out, toAlarmOutput(alarm))
	}
	return out, nil
}

func toAlarmOutput(a database.Alarm) output.Alarm {
	return output.Alarm{
		AlarmID:        a.AlarmID,
		UserID:         a.UserID,
		Type:           a.Type,
		Target:         a.Target,
		Enable:         a.Enable,
		Name:           a.Name,
		Hour:           a.Hour,
		Minute:         a.Minute,
		TimeDifference: a.TimeDifference,
		CharaID:        a.CharaID,
		CharaName:      a.CharaName,
		VoiceFileName:  a.VoiceFileName,
		Sunday:         a.Sunday,
		Monday:         a.Monday,
		Tuesday:        a.Tuesday,
		Wednesday:      a.Wednesday,
		Thursday:       a.Thursday,
		Friday:         a.Friday,
		Saturday:       a.Saturday,
	}
}
