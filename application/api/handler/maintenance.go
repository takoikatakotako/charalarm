package handler

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"net/http"
)

type Maintenance struct{}

func (m *Maintenance) MaintenanceGet(c echo.Context) error {
	res := response.Maintenance{
		Maintenance: false,
	}
	return c.JSON(http.StatusOK, res)
}
