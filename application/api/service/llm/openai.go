package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

const openAIChatCompletionsURL = "https://api.openai.com/v1/chat/completions"

const defaultOpenAIModel = "gpt-4o-mini"

// OpenAIClient は OpenAI Chat Completions API を叩く Client 実装。
type OpenAIClient struct {
	APIKey     string
	Model      string
	HTTPClient *http.Client
}

// NewOpenAIClient は OpenAIClient を生成する。model が空ならデフォルトモデルを使う。
func NewOpenAIClient(apiKey string, model string) *OpenAIClient {
	if model == "" {
		model = defaultOpenAIModel
	}
	return &OpenAIClient{
		APIKey:     apiKey,
		Model:      model,
		HTTPClient: &http.Client{Timeout: 30 * time.Second},
	}
}

type openAIRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

type openAIResponse struct {
	Choices []struct {
		Message Message `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// Chat はメッセージ列を OpenAI に送り、アシスタントの応答テキストを返す。
func (c *OpenAIClient) Chat(ctx context.Context, messages []Message) (string, error) {
	if c.APIKey == "" {
		return "", errors.New("openai api key is not set")
	}

	reqBody := openAIRequest{Model: c.Model, Messages: messages}
	b, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, openAIChatCompletionsURL, bytes.NewReader(b))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.APIKey)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var out openAIResponse
	if err := json.Unmarshal(body, &out); err != nil {
		return "", fmt.Errorf("failed to decode openai response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		if out.Error != nil {
			return "", fmt.Errorf("openai error: %s", out.Error.Message)
		}
		return "", fmt.Errorf("openai request failed: status %d", resp.StatusCode)
	}

	if len(out.Choices) == 0 {
		return "", errors.New("openai returned no choices")
	}

	return out.Choices[0].Message.Content, nil
}
