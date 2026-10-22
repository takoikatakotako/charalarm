package handler

import (
	"crypto/subtle"
	"log/slog"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service"
)

type RevenueCat struct {
	Service service.RevenueCat
	// Authorization は RevenueCat の Webhook に設定した Authorization ヘッダの値。空なら受けない。
	Authorization string
}

type revenueCatWebhookRequest struct {
	Event service.RevenueCatEvent `json:"event"`
}

// WebhookPost は RevenueCat から購入・更新・期限切れなどの知らせを受ける。
func (h *RevenueCat) WebhookPost(c echo.Context) error {
	if h.Authorization == "" {
		return c.JSON(http.StatusServiceUnavailable, response.Message{Message: "Service Unavailable"})
	}
	got := c.Request().Header.Get("Authorization")
	if subtle.ConstantTimeCompare([]byte(got), []byte(h.Authorization)) != 1 {
		return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
	}

	req := new(revenueCatWebhookRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, response.Message{Message: "Bad Request"})
	}

	if err := h.Service.HandleEvent(req.Event, time.Now()); err != nil {
		slog.Error("revenuecat webhook failed", slog.String("type", req.Event.Type), slog.String("error", err.Error()))
		return c.JSON(http.StatusInternalServerError, response.Message{Message: "Error!"})
	}
	return c.JSON(http.StatusOK, response.Message{Message: "OK"})
}
