package handler2

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"github.com/takoikatakotako/charalarm-api/service2"
	"net/http"
)

type Chara struct {
	Service service2.Chara
}

func (chara *Chara) CharaListGet(c echo.Context) error {
	res, err := chara.Service.GetCharaList()
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	return c.JSON(http.StatusOK, res)
}

func (chara *Chara) CharaIDGet(c echo.Context) error {
	charaID := c.Param("id")
	res, err := chara.Service.GetChara(charaID)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	return c.JSON(http.StatusOK, res)
}
