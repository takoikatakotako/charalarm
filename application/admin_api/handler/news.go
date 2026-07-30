package handler

import (
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

type News struct {
	Service service.News
}

type newsResponse struct {
	NewsID       string `json:"newsId"`
	Title        string `json:"title"`
	Body         string `json:"body"`
	RegisteredAt string `json:"registeredAt"`
}

type newsListResponse struct {
	News []newsResponse `json:"news"`
}

type newsCreateRequest struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

func (n *News) NewsListGet(c echo.Context) error {
	newsList, err := n.Service.ScanNews()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("scan_news_failed", err.Error()))
	}

	res := make([]newsResponse, 0, len(newsList))
	for _, item := range newsList {
		res = append(res, toNewsResponse(item))
	}
	return c.JSON(http.StatusOK, newsListResponse{News: res})
}

func (n *News) NewsPost(c echo.Context) error {
	req := new(newsCreateRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	title := strings.TrimSpace(req.Title)
	body := strings.TrimSpace(req.Body)
	if title == "" || body == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", "title and body are required"))
	}

	created, err := n.Service.CreateNews(title, body)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("create_news_failed", err.Error()))
	}
	return c.JSON(http.StatusOK, toNewsResponse(created))
}

func (n *News) NewsDelete(c echo.Context) error {
	newsID := c.Param("newsID")
	if newsID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_news_id", "newsID is required"))
	}

	if err := n.Service.DeleteNews(newsID); err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("delete_news_failed", err.Error()))
	}
	return c.NoContent(http.StatusNoContent)
}

func toNewsResponse(n output.News) newsResponse {
	return newsResponse{
		NewsID:       n.NewsID,
		Title:        n.Title,
		Body:         n.Body,
		RegisteredAt: n.RegisteredAt,
	}
}
