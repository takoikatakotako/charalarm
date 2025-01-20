package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/request"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"github.com/takoikatakotako/charalarm-api/service2"
	"github.com/takoikatakotako/charalarm-api/util/auth"
	"net/http"
)

type User struct {
	Service service2.User
}

func (u *User) UserInfoGet(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err := u.Service.GetUser(userID, authToken)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserSignupPost(c echo.Context) error {
	req := new(request.UserSignUp)
	if err := c.Bind(&req); err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	ipAddress := c.RealIP()

	res, err := u.Service.Signup(req.UserID, req.AuthToken, req.Platform, ipAddress)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
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

	req := new(request.UserUpdatePremiumPlan)
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
