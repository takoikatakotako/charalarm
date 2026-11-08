package handler

import (
	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"net/http"
)

type Chara struct {
	Service service.Chara
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
	charaID := c.Param("charaID")
	res, err := chara.Service.GetChara(charaID)
	if err != nil {
		res := response.Message{Message: "Error!"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	return c.JSON(http.StatusOK, res)
}

// CharaPresetsGet は「自分のキャラ」の土台になるキャラの一覧を返す。
func (chara *Chara) CharaPresetsGet(c echo.Context) error {
	res, err := chara.Service.GetPresetList()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}
	return c.JSON(http.StatusOK, res)
}
