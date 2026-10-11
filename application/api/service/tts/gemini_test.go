package tts

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGeminiClientSynthesize(t *testing.T) {
	pcm := make([]byte, 48000) // 24kHz 16bit mono で 1 秒
	var gotPath string
	var gotBody map[string]any

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		b, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(b, &gotBody)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"candidates": []any{map[string]any{
				"content": map[string]any{"parts": []any{
					map[string]any{"inlineData": map[string]any{
						"mimeType": "audio/L16;codec=pcm;rate=24000",
						"data":     base64.StdEncoding.EncodeToString(pcm),
					}},
				}},
			}},
		})
	}))
	defer server.Close()

	client := &GeminiClient{Project: "sandbox", Endpoint: server.URL, HTTPClient: server.Client()}
	audio, err := client.Synthesize(context.Background(), "おはようなのだ", Voice{
		Model: "gemini-3.8-flash-tts",
		Name:  "ja-jp-advisor-5",
		Style: "明るく",
	})
	assert.NoError(t, err)

	assert.Equal(t, "/v1/projects/sandbox/locations/global/publishers/google/models/gemini-3.8-flash-tts:generateContent", gotPath)
	assert.Equal(t, "ja-jp-advisor-5", gotBody["generationConfig"].(map[string]any)["speechConfig"].(map[string]any)["voiceConfig"].(map[string]any)["voice"])
	part := gotBody["contents"].([]any)[0].(map[string]any)["parts"].([]any)[0].(map[string]any)
	assert.Equal(t, "おはようなのだ", part["text"])
	assert.Equal(t, "明るく", part["speechMetadata"].(map[string]any)["style"])

	assert.Equal(t, 1.0, audio.Seconds)
	data, rate, err := parseWAV(audio.WAV)
	assert.NoError(t, err)
	assert.Equal(t, 24000, rate)
	assert.Equal(t, pcm, data)
}

func TestGeminiClientSynthesizeError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte(`{"error":{"message":"permission denied"}}`))
	}))
	defer server.Close()

	client := &GeminiClient{Project: "sandbox", Endpoint: server.URL, HTTPClient: server.Client()}
	_, err := client.Synthesize(context.Background(), "x", Voice{Model: "m", Name: "v"})
	assert.ErrorContains(t, err, "permission denied")
}

func TestToPCM(t *testing.T) {
	pcm := []byte{1, 2, 3, 4}

	// WAV ならヘッダを外す
	data, rate := toPCM(encodeWAV(pcm, 16000), "audio/wav")
	assert.Equal(t, pcm, data)
	assert.Equal(t, 16000, rate)

	// L16 ならそのまま
	data, rate = toPCM(pcm, "audio/L16;codec=pcm;rate=24000")
	assert.Equal(t, pcm, data)
	assert.Equal(t, 24000, rate)

	// レートが無ければ 0
	_, rate = toPCM(pcm, "audio/L16")
	assert.Equal(t, 0, rate)
}
