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
		Language: req.Language,
		Memory:   req.Memory,
		Messages: make([]llm.Message, 0, len(req.Messages)),
	}
	if req.Context != nil {
		input.Context = &service.ChatContext{Now: req.Context.Now, TimeZone: req.Context.TimeZone}
	}
	input.Capabilities = req.Capabilities
	for _, m := range req.Messages {
		message := llm.Message{Role: llm.Role(m.Role), Content: m.Content, ToolCallID: m.ToolCallID}
		for _, call := range m.ToolCalls {
			message.ToolCalls = append(message.ToolCalls, llm.ToolCall{
				ID: call.ID, Name: call.Name, Arguments: call.Arguments, Signature: call.Signature,
			})
		}
		input.Messages = append(input.Messages, message)
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

	if len(reply.ToolCalls) == 0 {
		return c.JSON(http.StatusOK, response.Chat{Type: "message", Message: reply.Text})
	}
	calls := make([]response.ChatToolCall, 0, len(reply.ToolCalls))
	for _, call := range reply.ToolCalls {
		arguments := call.Arguments
		if arguments == nil {
			arguments = map[string]any{}
		}
		calls = append(calls, response.ChatToolCall{ID: call.ID, Name: call.Name, Arguments: arguments, Signature: call.Signature})
	}
	return c.JSON(http.StatusOK, response.Chat{Type: "toolCall", Message: reply.Text, Calls: calls})
}
