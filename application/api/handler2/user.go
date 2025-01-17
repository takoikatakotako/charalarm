package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/request"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"github.com/takoikatakotako/charalarm-api/service2"
	"github.com/takoikatakotako/charalarm-api/util/auth"
	"net/http"
)

type User struct {
	Service service2.User
}

func (u *User) UserSignupPost(c echo.Context) error {
	req := new(request.UserSignUp)
	if err := c.Bind(&req); err != nil {
		return c.String(http.StatusInternalServerError, "Error!")
	}
	ipAddress := c.RealIP()

	res, err := u.Service.Signup(req.UserID, req.AuthToken, req.Platform, ipAddress)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Error!")
	}
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserWithdrawPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Error!")
	}

	err = u.Service.Withdraw(userID, authToken)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Error!")
	}

	res := response2.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserInfoGet(c echo.Context) error {
	res := response2.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}
