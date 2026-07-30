package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
)

type News struct {
	Service service.News
}

func (n *News) NewsListGet(c echo.Context) error {
	newsList, err := n.Service.ListNews()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	res := make([]response.News, 0, len(newsList))
	for _, item := range newsList {
		res = append(res, response.News{
			NewsID:       item.NewsID,
			Title:        item.Title,
			Body:         item.Body,
			RegisteredAt: item.RegisteredAt,
		})
	}
	return c.JSON(http.StatusOK, res)
}
