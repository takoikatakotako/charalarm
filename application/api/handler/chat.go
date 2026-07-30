package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/auth"
	"github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/service/llm"
)

type Chat struct {
	Service service.Chat
}

// ChatPost は会話メッセージ列を受け取り、ずんだもんの応答を返す。
func (h *Chat) ChatPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	req := new(request.Chat)
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	messages := make([]llm.Message, 0, len(req.Messages))
	for _, m := range req.Messages {
		messages = append(messages, llm.Message{Role: llm.Role(m.Role), Content: m.Content})
	}

	reply, err := h.Service.Reply(c.Request().Context(), userID, authToken, messages)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	return c.JSON(http.StatusOK, response.Chat{Message: reply})
}
