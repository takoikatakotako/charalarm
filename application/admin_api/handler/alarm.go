package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

type Alarm struct {
	Service service.Alarm
}

type alarmResponse struct {
	AlarmID        string  `json:"alarmID"`
	UserID         string  `json:"userID"`
	Type           string  `json:"type"`
	Target         string  `json:"target"`
	Enable         bool    `json:"enable"`
	Name           string  `json:"name"`
	Hour           int     `json:"hour"`
	Minute         int     `json:"minute"`
	TimeDifference float32 `json:"timeDifference"`
	CharaID        string  `json:"charaID"`
	CharaName      string  `json:"charaName"`
	VoiceFileName  string  `json:"voiceFileName"`
	Sunday         bool    `json:"sunday"`
	Monday         bool    `json:"monday"`
	Tuesday        bool    `json:"tuesday"`
	Wednesday      bool    `json:"wednesday"`
	Thursday       bool    `json:"thursday"`
	Friday         bool    `json:"friday"`
	Saturday       bool    `json:"saturday"`
}

type userAlarmsResponse struct {
	Alarms []alarmResponse `json:"alarms"`
}

func (a *Alarm) UserAlarmsGet(c echo.Context) error {
	userID := c.Param("userID")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_user_id", "userID is required"))
	}

	alarms, err := a.Service.ListByUser(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("list_alarms_failed", err.Error()))
	}

	res := make([]alarmResponse, 0, len(alarms))
	for _, alarm := range alarms {
		res = append(res, toAlarmResponse(alarm))
	}

	return c.JSON(http.StatusOK, userAlarmsResponse{Alarms: res})
}

func toAlarmResponse(a output.Alarm) alarmResponse {
	return alarmResponse{
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
