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

type Weather struct {
	Service service.Weather
}

// WeatherPost はユーザーが選んだ地域の今日の天気を返す (アプリのトップに出す)。
// 地域はログに出さない。
func (h *Weather) WeatherPost(c echo.Context) error {
	userID, authToken, err := auth.Basic(c.Request().Header.Get("Authorization"))
	if err != nil {
		return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
	}

	req := new(request.Weather)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
	}

	res, err := h.Service.Today(c.Request().Context(), userID, authToken, req.Region)
	if err != nil {
		if errors.Is(err, service.ErrWeatherNotConfigured) {
			return c.JSON(http.StatusServiceUnavailable, response.Message{Message: "Service Unavailable"})
		}
		switch err.Error() {
		case common.ErrorInvalidValue:
			return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
		case common.ErrorAuthenticationFailure:
			return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
		}
		slog.Error("weather failed", slog.String("error", err.Error()))
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}
	return c.JSON(http.StatusOK, res)
}
