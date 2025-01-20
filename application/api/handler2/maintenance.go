package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"net/http"
)

type Maintenance struct{}

func (m *Maintenance) MaintenanceGet(c echo.Context) error {
	res := response2.Maintenance{
		Maintenance: false,
	}
	return c.JSON(http.StatusOK, res)
}
