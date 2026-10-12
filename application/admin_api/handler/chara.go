package handler

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

type Chara struct {
	Service service.Chara
}

type charaProfileJSON struct {
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

// charaSettingsJSON は管理画面で編集する項目。追加・編集のリクエストと、レスポンスで同じ形にする。
type charaSettingsJSON struct {
	Enable       bool               `json:"enable"`
	Name         string             `json:"name"`
	Description  string             `json:"description"`
	Profiles     []charaProfileJSON `json:"profiles"`
	DisplayOrder int                `json:"displayOrder"`
	// 見た目のタイプ: "illustration" / "vrm"
	AppearanceType string `json:"appearanceType"`
	VRMFileName    string `json:"vrmFileName"`
	// 会話のタイプ: "none" / "voicevox" / "gemini"
	ConversationType   string `json:"conversationType"`
	ConversationPrompt string `json:"conversationPrompt"`
	VoicevoxStyleID    int    `json:"voicevoxStyleID"`
	GeminiVoice        string `json:"geminiVoice"`
	GeminiVoiceStyle   string `json:"geminiVoiceStyle"`
	// 通話の場面のプロンプト。空なら API がサーバの既定を使う。
	CallOpeningPrompt       string `json:"callOpeningPrompt"`
	CallEndingPrompt        string `json:"callEndingPrompt"`
	CallNoInputEndingPrompt string `json:"callNoInputEndingPrompt"`
}

type charaResponse struct {
	CharaID     string                             `json:"charaID"`
	CreatedAt   string                             `json:"createdAt"`
	UpdatedAt   string                             `json:"updatedAt"`
	Calls       []charaCallResponse                `json:"calls"`
	Expressions map[string]charaExpressionResponse `json:"expressions"`
	charaSettingsJSON
}

type charaListResponse struct {
	Charas []charaResponse `json:"charas"`
}

type charaCreateRequest struct {
	CharaID string `json:"charaID"`
	charaSettingsJSON
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

func (h *Chara) CharaPost(c echo.Context) error {
	req := new(charaCreateRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	created, err := h.Service.CreateChara(req.CharaID, toCharaSettings(req.charaSettingsJSON))
	if err != nil {
		return charaErrorResponse(c, "create_chara_failed", err)
	}
	return c.JSON(http.StatusCreated, toCharaResponse(created))
}

func (h *Chara) CharaPut(c echo.Context) error {
	charaID := c.Param("charaID")
	if charaID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_chara_id", "charaID is required"))
	}

	req := new(charaSettingsJSON)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	updated, err := h.Service.UpdateChara(charaID, toCharaSettings(*req))
	if err != nil {
		return charaErrorResponse(c, "update_chara_failed", err)
	}
	return c.JSON(http.StatusOK, toCharaResponse(updated))
}

func charaErrorResponse(c echo.Context, code string, err error) error {
	switch {
	case errors.Is(err, service.ErrInvalidChara):
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_chara", err.Error()))
	case errors.Is(err, service.ErrCharaAlreadyExists):
		return c.JSON(http.StatusConflict, newErrorResponse("chara_already_exists", err.Error()))
	default:
		return c.JSON(http.StatusInternalServerError, newErrorResponse(code, err.Error()))
	}
}

func toCharaSettings(req charaSettingsJSON) output.CharaSettings {
	profiles := make([]output.CharaProfile, 0, len(req.Profiles))
	for _, p := range req.Profiles {
		profiles = append(profiles, output.CharaProfile{Title: p.Title, Name: p.Name, URL: p.URL})
	}
	return output.CharaSettings{
		Enable:                  req.Enable,
		Name:                    req.Name,
		Description:             req.Description,
		Profiles:                profiles,
		DisplayOrder:            req.DisplayOrder,
		AppearanceType:          req.AppearanceType,
		VRMFileName:             req.VRMFileName,
		ConversationType:        req.ConversationType,
		ConversationPrompt:      req.ConversationPrompt,
		VoicevoxStyleID:         req.VoicevoxStyleID,
		GeminiVoice:             req.GeminiVoice,
		GeminiVoiceStyle:        req.GeminiVoiceStyle,
		CallOpeningPrompt:       req.CallOpeningPrompt,
		CallEndingPrompt:        req.CallEndingPrompt,
		CallNoInputEndingPrompt: req.CallNoInputEndingPrompt,
	}
}

func toCharaResponse(c output.Chara) charaResponse {
	s := c.Settings
	profiles := make([]charaProfileJSON, 0, len(s.Profiles))
	for _, p := range s.Profiles {
		profiles = append(profiles, charaProfileJSON{Title: p.Title, Name: p.Name, URL: p.URL})
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
		CharaID:     c.CharaID,
		CreatedAt:   c.CreatedAt,
		UpdatedAt:   c.UpdatedAt,
		Calls:       calls,
		Expressions: expressions,
		charaSettingsJSON: charaSettingsJSON{
			Enable:                  s.Enable,
			Name:                    s.Name,
			Description:             s.Description,
			Profiles:                profiles,
			DisplayOrder:            s.DisplayOrder,
			AppearanceType:          s.AppearanceType,
			VRMFileName:             s.VRMFileName,
			ConversationType:        s.ConversationType,
			ConversationPrompt:      s.ConversationPrompt,
			VoicevoxStyleID:         s.VoicevoxStyleID,
			GeminiVoice:             s.GeminiVoice,
			GeminiVoiceStyle:        s.GeminiVoiceStyle,
			CallOpeningPrompt:       s.CallOpeningPrompt,
			CallEndingPrompt:        s.CallEndingPrompt,
			CallNoInputEndingPrompt: s.CallNoInputEndingPrompt,
		},
	}
}
