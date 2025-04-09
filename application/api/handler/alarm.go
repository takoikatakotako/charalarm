package handler

import (
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/entity/request"
	"github.com/takoikatakotako/charalarm/api/entity/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/util/auth"
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

	res, err := a.Service.GetAlarmList(userID, authToken)
	if err != nil {
		fmt.Println("get alarm list failed")
		fmt.Println(err)
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

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

	req := new(request.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!2"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	fmt.Println("@@@@@@@@@@")
	fmt.Println(req)
	fmt.Println("@@@@@@@@@@")

	err = a.Service.AddAlarm(userID, authToken, req.Alarm)
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

	req := new(request.AddAlarmRequest)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = a.Service.EditAlarm(userID, authToken, req.Alarm)
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

	req := new(request.DeleteAlarmRequest)
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
