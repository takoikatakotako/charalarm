package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

type Chara struct {
	Service service.Chara
}

type charaProfileResponse struct {
	Title string `json:"title"`
	Name  string `json:"name"`
	URL   string `json:"url"`
}

type charaCallResponse struct {
	Message       string `json:"message"`
	VoiceFileName string `json:"voiceFileName"`
}

type charaExpressionResponse struct {
	ImageFileNames []string `json:"imageFileNames"`
	VoiceFileNames []string `json:"voiceFileNames"`
}

type charaResponse struct {
	CharaID            string                             `json:"charaID"`
	Enable             bool                               `json:"enable"`
	CreatedAt          string                             `json:"createdAt"`
	UpdatedAt          string                             `json:"updatedAt"`
	Name               string                             `json:"name"`
	Description        string                             `json:"description"`
	Profiles           []charaProfileResponse             `json:"profiles"`
	Calls              []charaCallResponse                `json:"calls"`
	Expressions        map[string]charaExpressionResponse `json:"expressions"`
	ConversationPrompt string                             `json:"conversationPrompt"`
	VoicevoxStyleID    int                                `json:"voicevoxStyleID"`
}

type charaListResponse struct {
	Charas []charaResponse `json:"charas"`
}

type charaUpdateRequest struct {
	Enable             bool   `json:"enable"`
	Name               string `json:"name"`
	Description        string `json:"description"`
	ConversationPrompt string `json:"conversationPrompt"`
	VoicevoxStyleID    int    `json:"voicevoxStyleID"`
}

func (h *Chara) CharaListGet(c echo.Context) error {
	charaList, err := h.Service.ScanCharas()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("scan_charas_failed", err.Error()))
	}

	res := make([]charaResponse, 0, len(charaList))
	for _, chara := range charaList {
		res = append(res, toCharaResponse(chara))
	}
	return c.JSON(http.StatusOK, charaListResponse{Charas: res})
}

func (h *Chara) CharaGet(c echo.Context) error {
	charaID := c.Param("charaID")
	if charaID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_chara_id", "charaID is required"))
	}

	chara, err := h.Service.GetChara(charaID)
	if err != nil {
		return c.JSON(http.StatusNotFound, newErrorResponse("chara_not_found", err.Error()))
	}
	return c.JSON(http.StatusOK, toCharaResponse(chara))
}

func (h *Chara) CharaPut(c echo.Context) error {
	charaID := c.Param("charaID")
	if charaID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_chara_id", "charaID is required"))
	}

	req := new(charaUpdateRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	updated, err := h.Service.UpdateChara(charaID, output.CharaUpdate{
		Enable:             req.Enable,
		Name:               req.Name,
		Description:        req.Description,
		ConversationPrompt: req.ConversationPrompt,
		VoicevoxStyleID:    req.VoicevoxStyleID,
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("update_chara_failed", err.Error()))
	}
	return c.JSON(http.StatusOK, toCharaResponse(updated))
}

func toCharaResponse(c output.Chara) charaResponse {
	profiles := make([]charaProfileResponse, 0, len(c.Profiles))
	for _, p := range c.Profiles {
		profiles = append(profiles, charaProfileResponse{Title: p.Title, Name: p.Name, URL: p.URL})
	}

	calls := make([]charaCallResponse, 0, len(c.Calls))
	for _, call := range c.Calls {
		calls = append(calls, charaCallResponse{Message: call.Message, VoiceFileName: call.VoiceFileName})
	}

	expressions := make(map[string]charaExpressionResponse, len(c.Expressions))
	for name, e := range c.Expressions {
		expressions[name] = charaExpressionResponse{
			ImageFileNames: e.ImageFileNames,
			VoiceFileNames: e.VoiceFileNames,
		}
	}

	return charaResponse{
		CharaID:            c.CharaID,
		Enable:             c.Enable,
		CreatedAt:          c.CreatedAt,
		UpdatedAt:          c.UpdatedAt,
		Name:               c.Name,
		Description:        c.Description,
		Profiles:           profiles,
		Calls:              calls,
		Expressions:        expressions,
		ConversationPrompt: c.ConversationPrompt,
		VoicevoxStyleID:    c.VoicevoxStyleID,
	}
}
