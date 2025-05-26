package handler

import (
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/auth"
	request2 "github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/common"
	"net/http"
)

type User struct {
	Service service.User
}

func (u *User) UserInfoGet(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	userInfoOutput, err := u.Service.GetUser(userID, authToken)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := convertToUserResponse(userInfoOutput)
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserSignupPost(c echo.Context) error {
	req := new(request2.UserSignUp)
	if err := c.Bind(&req); err != nil {
		fmt.Println(err)
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	ipAddress := c.RealIP()

	err := u.Service.Signup(req.UserID, req.AuthToken, req.Platform, ipAddress)
	if err != nil {
		fmt.Println(err)
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := response.Message{
		Message: common.UserSignupSuccess,
	}

	return c.JSON(http.StatusOK, res)
}

func (u *User) UserUpdatePremiumPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	req := new(request2.UserUpdatePremiumPlan)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = u.Service.UpdatePremiumPlan(userID, authToken, req.EnablePremiumPlan)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := response.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserWithdrawPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = u.Service.Withdraw(userID, authToken)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := response.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}
