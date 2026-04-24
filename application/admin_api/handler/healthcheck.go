package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

type Healthcheck struct{}

type healthcheckResponse struct {
	Message string `json:"message"`
}

func (h *Healthcheck) HealthcheckGet(c echo.Context) error {
	return c.JSON(http.StatusOK, healthcheckResponse{Message: "Healthy"})
}
