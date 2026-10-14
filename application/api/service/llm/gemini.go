package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/takoikatakotako/charalarm/api/service/vertex"
)

const defaultGeminiModel = "gemini-3.1-flash-lite"

// GeminiClient は Vertex AI の Gemini を呼ぶ Client 実装。
type GeminiClient struct {
	Project string
	Model   string
	// ThinkingLevel は思考の深さ (例: MINIMAL)。会話は速さを優先して浅くする。
	// 空なら指定しない (モデルの既定)。対応する値はモデルによって違う。
	ThinkingLevel string
	Endpoint      string
	// HTTPClient は認証つきのクライアント (vertex.NewHTTPClient)。
	HTTPClient *http.Client
}

// NewGeminiClient は GeminiClient を生成する。model が空ならデフォルトモデルを使う。
func NewGeminiClient(project string, model string, thinkingLevel string, httpClient *http.Client) *GeminiClient {
	if model == "" {
		model = defaultGeminiModel
	}
	return &GeminiClient{
		Project:       project,
		Model:         model,
		ThinkingLevel: thinkingLevel,
		Endpoint:      vertex.Endpoint,
		HTTPClient:    httpClient,
	}
}

type geminiPart struct {
	Text             string                  `json:"text,omitempty"`
	Thought          bool                    `json:"thought,omitempty"`
	ThoughtSignature string                  `json:"thoughtSignature,omitempty"`
	FunctionCall     *geminiFunctionCall     `json:"functionCall,omitempty"`
	FunctionResponse *geminiFunctionResponse `json:"functionResponse,omitempty"`
}

type geminiFunctionCall struct {
	Name string         `json:"name"`
	Args map[string]any `json:"args,omitempty"`
}

type geminiFunctionResponse struct {
	Name     string         `json:"name"`
	Response map[string]any `json:"response"`
}

type geminiFunctionDeclaration struct {
	Name        string         `json:"name"`
	Description string         `json:"description"`
	Parameters  map[string]any `json:"parameters,omitempty"`
}

type geminiTool struct {
	FunctionDeclarations []geminiFunctionDeclaration `json:"functionDeclarations"`
}

type geminiContent struct {
	Role  string       `json:"role,omitempty"`
	Parts []geminiPart `json:"parts"`
}

type geminiThinkingConfig struct {
	ThinkingLevel string `json:"thinkingLevel"`
}

type geminiGenerationConfig struct {
	ThinkingConfig *geminiThinkingConfig `json:"thinkingConfig,omitempty"`
}

type geminiRequest struct {
	SystemInstruction *geminiContent         `json:"systemInstruction,omitempty"`
	Contents          []geminiContent        `json:"contents"`
	Tools             []geminiTool           `json:"tools,omitempty"`
	GenerationConfig  geminiGenerationConfig `json:"generationConfig"`
}

type geminiResponse struct {
	Candidates []struct {
		Content geminiContent `json:"content"`
	} `json:"candidates"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// Chat はメッセージ列を Gemini に送り、モデルの応答テキストを返す。
func (c *GeminiClient) Chat(ctx context.Context, messages []Message) (string, error) {
	result, err := c.ChatWithTools(ctx, messages, nil)
	if err != nil {
		return "", err
	}
	if result.Text == "" {
		return "", errors.New("gemini returned no text")
	}
	return result.Text, nil
}

// ChatWithTools は道具の定義つきで問い合わせる。モデルが道具を呼びたければ Result.ToolCalls に入る。
func (c *GeminiClient) ChatWithTools(ctx context.Context, messages []Message, tools []Tool) (Result, error) {
	systemInstruction, contents := toGeminiContents(messages)
	if len(contents) == 0 {
		return Result{}, errors.New("gemini requires at least one message")
	}

	reqBody := geminiRequest{SystemInstruction: systemInstruction, Contents: contents}
	if len(tools) > 0 {
		declarations := make([]geminiFunctionDeclaration, 0, len(tools))
		for _, tool := range tools {
			declarations = append(declarations, geminiFunctionDeclaration{
				Name: tool.Name, Description: tool.Description, Parameters: tool.Parameters,
			})
		}
		reqBody.Tools = []geminiTool{{FunctionDeclarations: declarations}}
	}
	if c.ThinkingLevel != "" {
		reqBody.GenerationConfig.ThinkingConfig = &geminiThinkingConfig{ThinkingLevel: c.ThinkingLevel}
	}
	b, err := json.Marshal(reqBody)
	if err != nil {
		return Result{}, err
	}

	url := fmt.Sprintf("%s/v1/projects/%s/locations/global/publishers/google/models/%s:generateContent",
		c.Endpoint, c.Project, c.Model)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(b))
	if err != nil {
		return Result{}, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return Result{}, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return Result{}, err
	}

	var out geminiResponse
	if err := json.Unmarshal(body, &out); err != nil {
		return Result{}, fmt.Errorf("failed to decode gemini response: status %d", resp.StatusCode)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		if out.Error != nil {
			return Result{}, fmt.Errorf("gemini error: %s", out.Error.Message)
		}
		return Result{}, fmt.Errorf("gemini request failed: status %d", resp.StatusCode)
	}
	if len(out.Candidates) == 0 {
		return Result{}, errors.New("gemini returned no candidates")
	}

	var result Result
	var text strings.Builder
	for _, p := range out.Candidates[0].Content.Parts {
		switch {
		case p.FunctionCall != nil:
			result.ToolCalls = append(result.ToolCalls, ToolCall{
				ID:        fmt.Sprintf("call_%d", len(result.ToolCalls)+1),
				Name:      p.FunctionCall.Name,
				Arguments: p.FunctionCall.Args,
				Signature: p.ThoughtSignature,
			})
		case !p.Thought:
			text.WriteString(p.Text)
		}
	}
	result.Text = strings.TrimSpace(text.String())
	if result.Text == "" && len(result.ToolCalls) == 0 {
		return Result{}, errors.New("gemini returned no text")
	}
	return result, nil
}

// toGeminiContents はメッセージ列を Gemini の形に変える。
//
//   - 先頭に続く system (キャラ設定・記憶・現在時刻など) は systemInstruction にまとめる。
//   - 途中の system (会話を終える指示など) は、その位置のまま user の発言として渡す。
//   - 会話が system だけのとき (最初のひと言) は、最後の system を user の発言にする。
//     Gemini は contents が空だと応答しないため。
//   - 同じ role が続いたら 1 つにまとめる。
func toGeminiContents(messages []Message) (*geminiContent, []geminiContent) {
	leading := 0
	for leading < len(messages) && messages[leading].Role == RoleSystem {
		leading++
	}
	if leading == len(messages) && leading > 0 {
		leading--
	}

	var systemInstruction *geminiContent
	if leading > 0 {
		systemInstruction = &geminiContent{}
		for _, m := range messages[:leading] {
			systemInstruction.Parts = append(systemInstruction.Parts, geminiPart{Text: m.Content})
		}
	}

	// tool の結果は、呼び出しの名前と一緒に返す必要があるので、ID から名前を引く
	toolNames := map[string]string{}
	for _, m := range messages {
		for _, call := range m.ToolCalls {
			toolNames[call.ID] = call.Name
		}
	}

	var contents []geminiContent
	for _, m := range messages[leading:] {
		role := "user"
		if m.Role == RoleAssistant {
			role = "model"
		}
		for _, part := range toGeminiParts(m, toolNames) {
			if n := len(contents); n > 0 && contents[n-1].Role == role {
				contents[n-1].Parts = append(contents[n-1].Parts, part)
				continue
			}
			contents = append(contents, geminiContent{Role: role, Parts: []geminiPart{part}})
		}
	}
	return systemInstruction, contents
}

// toGeminiParts は1つのメッセージを Gemini の parts にする。
//   - assistant の道具の呼び出しは functionCall (思考の署名を付けて返す)
//   - tool の結果は functionResponse
//   - それ以外は text
func toGeminiParts(m Message, toolNames map[string]string) []geminiPart {
	switch {
	case m.Role == RoleTool:
		return []geminiPart{{FunctionResponse: &geminiFunctionResponse{
			Name:     toolNames[m.ToolCallID],
			Response: map[string]any{"content": m.Content},
		}}}
	case len(m.ToolCalls) > 0:
		parts := make([]geminiPart, 0, len(m.ToolCalls)+1)
		if m.Content != "" {
			parts = append(parts, geminiPart{Text: m.Content})
		}
		for _, call := range m.ToolCalls {
			parts = append(parts, geminiPart{
				FunctionCall:     &geminiFunctionCall{Name: call.Name, Args: call.Arguments},
				ThoughtSignature: call.Signature,
			})
		}
		return parts
	default:
		return []geminiPart{{Text: m.Content}}
	}
}
