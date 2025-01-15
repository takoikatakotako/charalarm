package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"net/http"
)

type Alarm struct{}

func (a *Alarm) AlarmListGet(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmAddPost(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmEditPost(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}

func (a *Alarm) AlarmDeletePost(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: true,
	}
	return c.JSON(http.StatusOK, res)
}
