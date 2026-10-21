package handler

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/auth"
	"github.com/takoikatakotako/charalarm/api/handler/request"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/common"
)

type TextToSpeech struct {
	Service service.TextToSpeech
}

// TextToSpeechPost はキャラの発話テキストを音声 (WAV) にして返す。
func (h *TextToSpeech) TextToSpeechPost(c echo.Context) error {
	authorizationHeader := c.Request().Header.Get("Authorization")
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
	}

	req := new(request.TextToSpeech)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
	}

	audio, err := h.Service.Synthesize(c.Request().Context(), userID, authToken, req.CharaID, req.Text)
	if err != nil {
		if errors.Is(err, service.ErrTTSNotConfigured) {
			return c.JSON(http.StatusServiceUnavailable, response.Message{Message: "Service Unavailable"})
		}
		switch err.Error() {
		case common.ErrorInvalidValue:
			return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
		case common.ErrorAuthenticationFailure:
			return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
		}
		slog.Error("tts failed", slog.String("chara", req.CharaID), slog.String("error", err.Error()))
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}

	return c.Blob(http.StatusOK, "audio/wav", audio.WAV)
}
