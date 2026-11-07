package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/api/service/appcheck"
)

func TestAppCheckMiddleware(t *testing.T) {
	ok := func(c echo.Context) error { return c.NoContent(http.StatusOK) }
	// トークンの無いリクエスト (4.x のアプリなど)
	call := func(handler echo.HandlerFunc) int {
		e := echo.New()
		rec := httptest.NewRecorder()
		handler(e.NewContext(httptest.NewRequest(http.MethodPost, "/chat", nil), rec))
		return rec.Code
	}
	verifier := appcheck.NewVerifier("983259461023")

	t.Run("monitor では弾かない", func(t *testing.T) {
		a := AppCheck{Verifier: verifier, Mode: AppCheckModeMonitor}
		assert.Equal(t, http.StatusOK, call(a.Require(ok)))
		assert.Equal(t, http.StatusOK, call(a.Monitor(ok)))
	})

	t.Run("enforce では Require だけ弾く", func(t *testing.T) {
		a := AppCheck{Verifier: verifier, Mode: AppCheckModeEnforce}
		assert.Equal(t, http.StatusUnauthorized, call(a.Require(ok)))
		assert.Equal(t, http.StatusOK, call(a.Monitor(ok)))
	})

	t.Run("設定が無ければ何もしない", func(t *testing.T) {
		assert.Equal(t, http.StatusOK, call(AppCheck{Mode: AppCheckModeEnforce}.Require(ok)))
		assert.Equal(t, http.StatusOK, call(AppCheck{Verifier: verifier, Mode: AppCheckModeOff}.Require(ok)))
	})
}
