package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"net/http"
)

type PushToken struct{}

func (p *PushToken) PushTokenPushAdd(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}

func (p *PushToken) PushTokenVoIPPushAdd(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}
