package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/request"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"github.com/takoikatakotako/charalarm-api/service2"
	"github.com/takoikatakotako/charalarm-api/util/auth"
	"net/http"
)

type Alarm struct {
	Service service2.Alarm
}

func (a *Alarm) AlarmListGet(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err := a.Service.GetAlarmList(userID, authToken)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmAddPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = a.Service.AddAlarm(userID, authToken, req.Alarm)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response2.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmEditPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = a.Service.EditAlarm(userID, authToken, req.Alarm)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response2.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmDeletePost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request.DeleteAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = a.Service.DeleteAlarm(userID, authToken, req.AlarmID)
	if err != nil {
		res := response2.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response2.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}
