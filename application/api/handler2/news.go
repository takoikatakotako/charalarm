package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity2/response2"
	"net/http"
)

type News struct {
}

func (n *News) NewsListGet(c echo.Context) error {
	res := response2.Message{
		Message: Healthy,
	}
	return c.JSON(http.StatusOK, res)
}
