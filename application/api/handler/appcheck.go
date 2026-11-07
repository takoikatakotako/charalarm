package handler

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/api/handler/response"
	"github.com/takoikatakotako/charalarm/api/service/appcheck"
)

// AppCheckHeader はアプリが Firebase App Check のトークンを入れるヘッダ。
const AppCheckHeader = "X-Firebase-AppCheck"

// AppCheck の動かし方。
const (
	// AppCheckModeOff は確かめない (Firebase のプロジェクト番号が無い環境)。
	AppCheckModeOff = "off"
	// AppCheckModeMonitor は確かめて結果をログに出すだけで、弾かない。
	AppCheckModeMonitor = "monitor"
	// AppCheckModeEnforce は Require を付けたエンドポイントで、正しいトークンの無いリクエストを弾く。
	AppCheckModeEnforce = "enforce"
)

// AppCheck は本物のアプリからのリクエストかを Firebase App Check のトークンで確かめる。
// 結果はログに出して数える (ユーザーを特定する情報は出さない)。
type AppCheck struct {
	// Verifier が nil なら何もしない。
	Verifier *appcheck.Verifier
	Mode     string
}

// Monitor は確かめて記録するだけで、弾かない。
// 4.x のアプリはトークンを送らないので、4.x も使うエンドポイント (ユーザー登録など) に付ける。
func (a AppCheck) Monitor(next echo.HandlerFunc) echo.HandlerFunc {
	return a.middleware(next, false)
}

// Require は enforce のとき、正しいトークンの無いリクエストを 401 で弾く。
// 費用のかかる新しいエンドポイント (/chat, /tts, /weather) に付ける。
func (a AppCheck) Require(next echo.HandlerFunc) echo.HandlerFunc {
	return a.middleware(next, a.Mode == AppCheckModeEnforce)
}

func (a AppCheck) middleware(next echo.HandlerFunc, enforce bool) echo.HandlerFunc {
	return func(c echo.Context) error {
		if a.Verifier == nil || a.Mode == AppCheckModeOff || a.Mode == "" {
			return next(c)
		}
		path := c.Path()
		claims, err := a.Verifier.Verify(c.Request().Context(), c.Request().Header.Get(AppCheckHeader))
		switch {
		case err == nil:
			slog.Info("app check", slog.String("path", path), slog.String("result", "ok"), slog.String("app", claims.Subject))
		case isTokenProblem(err):
			slog.Info("app check", slog.String("path", path), slog.String("result", "rejected"), slog.String("reason", err.Error()), slog.Bool("enforced", enforce))
			if enforce {
				return c.JSON(http.StatusUnauthorized, response.Message{Message: "Unauthorized"})
			}
		default:
			// Firebase の公開鍵を取れないなど、サーバ側の問題。アプリのせいではないので通す
			slog.Warn("app check unavailable", slog.String("path", path), slog.String("error", err.Error()))
		}
		return next(c)
	}
}

// isTokenProblem はトークン (アプリ側) の問題か。
func isTokenProblem(err error) bool {
	for _, target := range []error{appcheck.ErrMissing, appcheck.ErrMalformed, appcheck.ErrSignature, appcheck.ErrClaims, appcheck.ErrExpired} {
		if errors.Is(err, target) {
			return true
		}
	}
	return false
}
