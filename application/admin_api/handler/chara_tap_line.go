package handler

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type CharaTapLine struct {
	Service service.CharaTapLine
}

type tapLineWhenJSON struct {
	Dates    []string `json:"dates"`
	Hours    []int    `json:"hours"`
	Weekdays []int    `json:"weekdays"`
}

type tapLineJSON struct {
	ID string `json:"id"`
	// Language は "ja" / "en"
	Language      string          `json:"language"`
	Text          string          `json:"text"`
	VoiceFileName string          `json:"voiceFileName"`
	Theme         string          `json:"theme"`
	When          tapLineWhenJSON `json:"when"`
}

type tapLineThemeResponse struct {
	Key   string          `json:"key"`
	Label string          `json:"label"`
	When  tapLineWhenJSON `json:"when"`
}

type tapLineThemesResponse struct {
	Themes []tapLineThemeResponse `json:"themes"`
}

type tapLineDraftsRequest struct {
	Theme    string `json:"theme"`
	Count    int    `json:"count"`
	Language string `json:"language"`
}

type tapLineDraftsResponse struct {
	Drafts []tapLineJSON `json:"drafts"`
}

type tapLinesRequest struct {
	TapLines []tapLineJSON `json:"tapLines"`
}

type tapLineVoicesRequest struct {
	IDs []string `json:"ids"`
}

func (h *CharaTapLine) ThemesGet(c echo.Context) error {
	themes := make([]tapLineThemeResponse, 0, len(service.TapLineThemes))
	for _, theme := range service.TapLineThemes {
		themes = append(themes, tapLineThemeResponse{Key: theme.Key, Label: theme.Label, When: toTapLineWhenJSON(theme.When)})
	}
	return c.JSON(http.StatusOK, tapLineThemesResponse{Themes: themes})
}

func (h *CharaTapLine) DraftsPost(c echo.Context) error {
	req := new(tapLineDraftsRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}
	drafts, err := h.Service.Drafts(c.Request().Context(), c.Param("charaID"), req.Theme, req.Count, req.Language)
	if err != nil {
		return tapLineErrorResponse(c, "make_drafts_failed", err)
	}
	res := make([]tapLineJSON, 0, len(drafts))
	for _, draft := range drafts {
		res = append(res, tapLineJSON{Text: draft.Text, Theme: draft.Theme, When: toTapLineWhenJSON(draft.When), Language: draft.Language})
	}
	return c.JSON(http.StatusOK, tapLineDraftsResponse{Drafts: res})
}

func (h *CharaTapLine) LinesPut(c echo.Context) error {
	req := new(tapLinesRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}
	lines := make([]database.CharaTapLine, 0, len(req.TapLines))
	for _, line := range req.TapLines {
		lines = append(lines, database.CharaTapLine{
			ID:       line.ID,
			Language: line.Language,
			Text:     line.Text,
			Theme:    line.Theme,
			When: database.CharaTapLineWhen{
				Dates: line.When.Dates, Hours: line.When.Hours, Weekdays: line.When.Weekdays,
			},
		})
	}
	updated, err := h.Service.SaveLines(c.Param("charaID"), lines)
	if err != nil {
		return tapLineErrorResponse(c, "save_tap_lines_failed", err)
	}
	return c.JSON(http.StatusOK, toCharaResponse(updated))
}

func (h *CharaTapLine) VoicesPost(c echo.Context) error {
	req := new(tapLineVoicesRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}
	updated, err := h.Service.MakeVoices(c.Request().Context(), c.Param("charaID"), req.IDs)
	if err != nil {
		return tapLineErrorResponse(c, "make_voices_failed", err)
	}
	return c.JSON(http.StatusOK, toCharaResponse(updated))
}

func tapLineErrorResponse(c echo.Context, code string, err error) error {
	if errors.Is(err, service.ErrVertexNotConfigured) {
		return c.JSON(http.StatusServiceUnavailable, newErrorResponse("vertex_not_configured", "Vertex AI (Gemini) が設定されていません"))
	}
	return charaErrorResponse(c, code, err)
}

func toTapLineWhenJSON(when database.CharaTapLineWhen) tapLineWhenJSON {
	return tapLineWhenJSON{Dates: nonNil(when.Dates), Hours: nonNilInt(when.Hours), Weekdays: nonNilInt(when.Weekdays)}
}

func nonNilInt(s []int) []int {
	if s == nil {
		return []int{}
	}
	return s
}
