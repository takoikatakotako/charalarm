package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/auth"
	"github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/common"
)

type Chat struct {
	Service service.Chat
}

// ChatPost は会話メッセージ列を受け取り、キャラの応答を返す。
// 会話の内容はログに出さない。
func (h *Chat) ChatPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
	}

	req := new(request.Chat)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
	}

	input := service.ChatInput{
		CharaID:  req.CharaID,
		Memory:   req.Memory,
		Messages: make([]llm.Message, 0, len(req.Messages)),
	}
	if req.Context != nil {
		input.Context = &service.ChatContext{Now: req.Context.Now, TimeZone: req.Context.TimeZone}
	}
	for _, m := range req.Messages {
		input.Messages = append(input.Messages, llm.Message{Role: llm.Role(m.Role), Content: m.Content})
	}

	reply, err := h.Service.Reply(c.Request().Context(), userID, authToken, input)
	if err != nil {
		switch err.Error() {
		case common.ErrorInvalidValue:
			return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
		case common.ErrorAuthenticationFailure:
			return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
		}
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	return c.JSON(http.StatusOK, response.Chat{Message: reply})
}
