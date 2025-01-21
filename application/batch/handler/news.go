package handler

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"net/http"
)

type News struct {
}

func (n *News) NewsListGet(c echo.Context) error {
	res := response.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}
