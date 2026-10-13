package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

type CharaResource struct {
	Service service.CharaResource
}

type resourceFileResponse struct {
	FileName     string    `json:"fileName"`
	Size         int64     `json:"size"`
	LastModified time.Time `json:"lastModified"`
}

type resourceFileListResponse struct {
	// BaseURL はファイルを配る CloudFront の URL ({baseURL}/{charaID}/{fileName})。プレビューに使う
	BaseURL string                 `json:"baseURL"`
	Files   []resourceFileResponse `json:"files"`
}

type uploadURLRequest struct {
	FileName string `json:"fileName"`
}

type uploadURLResponse struct {
	UploadURL   string `json:"uploadURL"`
	ContentType string `json:"contentType"`
}

type invalidateRequest struct {
	FileNames []string `json:"fileNames"`
}

type charaExpressionJSON struct {
	ImageFileNames []string `json:"imageFileNames"`
	VoiceFileNames []string `json:"voiceFileNames"`
}

type charaCallJSON struct {
	Message       string `json:"message"`
	VoiceFileName string `json:"voiceFileName"`
}

type charaAssetsRequest struct {
	Expressions map[string]charaExpressionJSON `json:"expressions"`
	Calls       []charaCallJSON                `json:"calls"`
}

func (h *CharaResource) FilesGet(c echo.Context) error {
	files, err := h.Service.ListFiles(c.Param("charaID"))
	if err != nil {
		return charaErrorResponse(c, "list_files_failed", err)
	}

	res := make([]resourceFileResponse, 0, len(files))
	for _, f := range files {
		res = append(res, resourceFileResponse{FileName: f.FileName, Size: f.Size, LastModified: f.LastModified})
	}
	return c.JSON(http.StatusOK, resourceFileListResponse{BaseURL: h.Service.BaseURL(), Files: res})
}

func (h *CharaResource) UploadURLPost(c echo.Context) error {
	req := new(uploadURLRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	url, contentType, err := h.Service.CreateUploadURL(c.Param("charaID"), req.FileName)
	if err != nil {
		return charaErrorResponse(c, "create_upload_url_failed", err)
	}
	return c.JSON(http.StatusOK, uploadURLResponse{UploadURL: url, ContentType: contentType})
}

func (h *CharaResource) InvalidatePost(c echo.Context) error {
	req := new(invalidateRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	if err := h.Service.InvalidateFiles(c.Param("charaID"), req.FileNames); err != nil {
		return charaErrorResponse(c, "invalidate_failed", err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *CharaResource) AssetsPut(c echo.Context) error {
	req := new(charaAssetsRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_request", err.Error()))
	}

	expressions := make(map[string]output.CharaExpression, len(req.Expressions))
	for name, e := range req.Expressions {
		expressions[name] = output.CharaExpression{ImageFileNames: nonNil(e.ImageFileNames), VoiceFileNames: nonNil(e.VoiceFileNames)}
	}
	calls := make([]output.CharaCall, 0, len(req.Calls))
	for _, call := range req.Calls {
		calls = append(calls, output.CharaCall{Message: call.Message, VoiceFileName: call.VoiceFileName})
	}

	updated, err := h.Service.UpdateAssets(c.Param("charaID"), expressions, calls)
	if err != nil {
		return charaErrorResponse(c, "update_assets_failed", err)
	}
	return c.JSON(http.StatusOK, toCharaResponse(updated))
}

// nonNil は空の配列を null ではなく [] で保存するため。
func nonNil(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}
