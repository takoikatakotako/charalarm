package handler

import (
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/auth"
	request2 "github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/service/input"
	"net/http"
)

type Alarm struct {
	Service service.Alarm
}

func (a *Alarm) AlarmListGet(c echo.Context) error {
	fmt.Println(c.Request())
	authorizationHeader := c.Request().Header.Get("Authorization")
	fmt.Println("-------")
	fmt.Println(c.Request().Header)
	fmt.Println("-------")

	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		fmt.Println("auth error")
		fmt.Println(err)
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	getAlarmResponse, err := a.Service.GetAlarms(userID, authToken)
	if err != nil {
		fmt.Println("get alarm list failed")
		fmt.Println(err)
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := convertToAlarmResponses(getAlarmResponse.Alarms)
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmAddPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		fmt.Println(err)
		res := response.Message{Message: "Error!1"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request2.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!2"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	fmt.Println("@@@@@@@@@@")
	fmt.Println(req)
	fmt.Println("@@@@@@@@@@")

	addAlarmInput := input.AddAlarm{
		UserID:    userID,
		AuthToken: authToken,
		Alarm:     convertToAlarmInput(req.Alarm),
	}

	err = a.Service.AddAlarm(addAlarmInput)
	if err != nil {
		fmt.Println(err)
		res := response.Message{Message: "Error!3"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmEditPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request2.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	editAlarmInput := input.EditAlarm{
		UserID:    userID,
		AuthToken: authToken,
		Alarm:     convertToAlarmInput(req.Alarm),
	}

	err = a.Service.EditAlarm(editAlarmInput)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmDeletePost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request2.DeleteAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = a.Service.DeleteAlarm(userID, authToken, req.AlarmID)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := response.Message{
		Message: "Health",
	}
	return c.JSON(http.StatusOK, res)
}
