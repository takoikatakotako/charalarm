package tts

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

const (
	vertexEndpoint    = "https://aiplatform.googleapis.com"
	cloudPlatformAuth = "https://www.googleapis.com/auth/cloud-platform"
	defaultSampleRate = 24000
)

// GeminiClient は Vertex AI の Gemini TTS を呼ぶ Client 実装。
type GeminiClient struct {
	Project    string
	Endpoint   string
	HTTPClient *http.Client
}

// NewGeminiClient は GeminiClient を生成する。
// credentialConfig (external_account の JSON) を渡すと Workload Identity 連携で認証する (Lambda 用)。
// 空ならアプリケーションのデフォルト認証情報を使う (ローカルでは gcloud auth application-default login)。
// トークンは最初の呼び出しで取得するので、ここでは通信しない。
func NewGeminiClient(ctx context.Context, project string, credentialConfig string) (*GeminiClient, error) {
	var creds *google.Credentials
	var err error
	if credentialConfig != "" {
		creds, err = google.CredentialsFromJSONWithType(ctx, []byte(credentialConfig), google.ExternalAccount, cloudPlatformAuth)
	} else {
		creds, err = google.FindDefaultCredentials(ctx, cloudPlatformAuth)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to load google credentials: %w", err)
	}

	httpClient := oauth2.NewClient(ctx, creds.TokenSource)
	httpClient.Timeout = 30 * time.Second
	return &GeminiClient{
		Project:    project,
		Endpoint:   vertexEndpoint,
		HTTPClient: httpClient,
	}, nil
}

type geminiPart struct {
	Text           string          `json:"text"`
	SpeechMetadata *speechMetadata `json:"speechMetadata,omitempty"`
}

type speechMetadata struct {
	Style string `json:"style"`
}

type geminiContent struct {
	Role  string       `json:"role"`
	Parts []geminiPart `json:"parts"`
}

type geminiRequest struct {
	Contents         []geminiContent `json:"contents"`
	GenerationConfig struct {
		ResponseModalities []string `json:"responseModalities"`
		SpeechConfig       struct {
			VoiceConfig struct {
				Voice string `json:"voice"`
			} `json:"voiceConfig"`
		} `json:"speechConfig"`
	} `json:"generationConfig"`
}

type geminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				InlineData *struct {
					MimeType string `json:"mimeType"`
					Data     string `json:"data"`
				} `json:"inlineData"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// Synthesize は text を voice で合成し、WAV を返す。
func (c *GeminiClient) Synthesize(ctx context.Context, text string, voice Voice) (Audio, error) {
	part := geminiPart{Text: text}
	if voice.Style != "" {
		part.SpeechMetadata = &speechMetadata{Style: voice.Style}
	}
	var reqBody geminiRequest
	reqBody.Contents = []geminiContent{{Role: "user", Parts: []geminiPart{part}}}
	reqBody.GenerationConfig.ResponseModalities = []string{"AUDIO"}
	reqBody.GenerationConfig.SpeechConfig.VoiceConfig.Voice = voice.Name

	b, err := json.Marshal(reqBody)
	if err != nil {
		return Audio{}, err
	}

	// Gemini TTS は global ロケーションだけで提供されている
	url := fmt.Sprintf("%s/v1/projects/%s/locations/global/publishers/google/models/%s:generateContent",
		c.Endpoint, c.Project, voice.Model)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(b))
	if err != nil {
		return Audio{}, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return Audio{}, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return Audio{}, err
	}

	var out geminiResponse
	if err := json.Unmarshal(body, &out); err != nil {
		return Audio{}, fmt.Errorf("failed to decode gemini response: status %d", resp.StatusCode)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		if out.Error != nil {
			return Audio{}, fmt.Errorf("gemini error: %s", out.Error.Message)
		}
		return Audio{}, fmt.Errorf("gemini request failed: status %d", resp.StatusCode)
	}

	var pcm []byte
	sampleRate := 0
	for _, candidate := range out.Candidates {
		for _, p := range candidate.Content.Parts {
			if p.InlineData == nil || p.InlineData.Data == "" {
				continue
			}
			data, err := base64.StdEncoding.DecodeString(p.InlineData.Data)
			if err != nil {
				return Audio{}, err
			}
			chunk, rate := toPCM(data, p.InlineData.MimeType)
			if sampleRate == 0 && rate > 0 {
				sampleRate = rate
			}
			pcm = append(pcm, chunk...)
		}
	}
	if len(pcm) == 0 {
		return Audio{}, errors.New("gemini returned no audio")
	}
	if sampleRate == 0 {
		sampleRate = defaultSampleRate
	}

	return Audio{
		WAV:     encodeWAV(pcm, sampleRate),
		Seconds: float64(len(pcm)) / float64(sampleRate*2),
	}, nil
}
