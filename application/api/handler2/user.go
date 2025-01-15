package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"net/http"
)

type User struct {
}

func (u *User) UserSignupPost(c echo.Context) error {
	res := response2.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}

func (u *User) UserWithdrawPost(c echo.Context) error {
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
