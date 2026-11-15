package handler

import (
	"context"
	"encoding/json"
	"hash/crc32"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/require"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/api/service/tts"
)

const myCharaTestUser = "11111111-1111-4111-8111-111111111111"
const myCharaTestToken = "22222222-2222-4222-8222-222222222222"

func writeMyCharaDynamoResponse(w http.ResponseWriter, value any) {
	data, err := json.Marshal(value)
	if err != nil {
		http.Error(w, "invalid test response", http.StatusInternalServerError)
		return
	}
	w.Header().Set("X-Amz-Crc32", strconv.FormatUint(uint64(crc32.ChecksumIEEE(data)), 10))
	_, _ = w.Write(data)
}

func myCharaTestDatabase(t *testing.T) *atomic.Int64 {
	t.Helper()
	usageWrites := &atomic.Int64{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var request struct {
			TableName string
			Key       map[string]map[string]string
		}
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "application/x-amz-json-1.0")
		if request.TableName == "usage-table" {
			usageWrites.Add(1)
			writeMyCharaDynamoResponse(w, map[string]any{"Attributes": map[string]any{
				"chat": map[string]string{"N": "1"}, "ttsChars": map[string]string{"N": "1"},
			}})
			return
		}
		if request.TableName == "user-table" {
			writeMyCharaDynamoResponse(w, map[string]any{"Item": map[string]any{
				"userID": map[string]string{"S": myCharaTestUser}, "authToken": map[string]string{"S": myCharaTestToken},
			}})
			return
		}
		preset := request.Key["charaID"]["S"] == "com.charalarm.preset.test"
		writeMyCharaDynamoResponse(w, map[string]any{"Item": map[string]any{
			"charaID": request.Key["charaID"], "enable": map[string]bool{"BOOL": true},
			"preset": map[string]bool{"BOOL": preset}, "conversationType": map[string]string{"S": "gemini"},
			"conversationPrompt": map[string]string{"S": "original-persona"}, "geminiVoiceStyle": map[string]string{"S": "base-style"},
		}})
	}))
	t.Cleanup(server.Close)
	t.Setenv("AWS_ENDPOINT_URL_DYNAMODB", server.URL)
	t.Setenv("AWS_REGION", "ap-northeast-1")
	t.Setenv("AWS_ACCESS_KEY_ID", "testing")
	t.Setenv("AWS_SECRET_ACCESS_KEY", "testing")
	t.Setenv("AWS_SESSION_TOKEN", "")
	t.Setenv("AWS_PROFILE", "")
	return usageWrites
}

type myCharaTestLLM struct{ messages []llm.Message }

func (c *myCharaTestLLM) Chat(_ context.Context, messages []llm.Message) (string, error) {
	c.messages = messages
	return "おはよう", nil
}

type myCharaTestTTS struct{ voice tts.Voice }

func (c *myCharaTestTTS) Synthesize(_ context.Context, _ string, voice tts.Voice) (tts.Audio, error) {
	c.voice = voice
	return tts.Audio{WAV: []byte("test-audio")}, nil
}

func TestMyCharaChatRequest(t *testing.T) {
	myCharaTestDatabase(t)
	client := &myCharaTestLLM{}
	handler := Chat{Service: service.Chat{LLMClient: client}}
	e := echo.New()
	e.POST("/chat", handler.ChatPost)
	body := `{"charaID":"com.charalarm.preset.test","myChara":{"name":"ユーザーの名前","personality":"穏やかな友達"},"messages":[{"role":"user","content":"おはよう"}]}`
	req := httptest.NewRequest(http.MethodPost, "/chat", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(myCharaTestUser, myCharaTestToken)
	response := httptest.NewRecorder()
	e.ServeHTTP(response, req)
	require.Equal(t, http.StatusOK, response.Code, response.Body.String())
	require.NotEmpty(t, client.messages)
	require.Contains(t, client.messages[0].Content, "ユーザーの名前")
	require.Contains(t, client.messages[0].Content, "穏やかな友達")
	require.NotContains(t, client.messages[0].Content, "original-persona")

	req = httptest.NewRequest(http.MethodPost, "/chat", strings.NewReader(strings.ReplaceAll(body, "com.charalarm.preset.test", "com.charalarm.official")))
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(myCharaTestUser, myCharaTestToken)
	response = httptest.NewRecorder()
	e.ServeHTTP(response, req)
	require.Equal(t, http.StatusBadRequest, response.Code)
}

func TestMyCharaSpeechRequest(t *testing.T) {
	myCharaTestDatabase(t)
	for _, tc := range []struct {
		name, charaID, voiceID string
		status                 int
	}{
		{"選んだ声", "com.charalarm.preset.test", "Kore", http.StatusOK},
		{"通常キャラの声は変えない", "com.charalarm.official", "Kore", http.StatusBadRequest},
		{"一覧外の声は使えない", "com.charalarm.preset.test", "voice_private", http.StatusBadRequest},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := &myCharaTestTTS{}
			handler := TextToSpeech{Service: service.TextToSpeech{Client: client, Voice: tts.Voice{Model: "configured-model"}}}
			e := echo.New()
			e.POST("/tts", handler.TextToSpeechPost)
			body, err := json.Marshal(map[string]string{"charaID": tc.charaID, "voiceID": tc.voiceID, "text": "おはよう"})
			require.NoError(t, err)
			req := httptest.NewRequest(http.MethodPost, "/tts", strings.NewReader(string(body)))
			req.Header.Set("Content-Type", "application/json")
			req.SetBasicAuth(myCharaTestUser, myCharaTestToken)
			response := httptest.NewRecorder()
			e.ServeHTTP(response, req)
			require.Equal(t, tc.status, response.Code, response.Body.String())
			if tc.status == http.StatusOK {
				require.Equal(t, tts.Voice{Model: "configured-model", Name: "Kore"}, client.voice)
				require.Equal(t, "audio/wav", response.Header().Get("Content-Type"))
			} else {
				require.Empty(t, client.voice.Name)
			}
		})
	}
}

func TestMyCharaRejectedSettingsDoNotConsumeUsage(t *testing.T) {
	usageWrites := myCharaTestDatabase(t)
	usage := &service.UsageLimit{DailyChat: 10, DailyTTSChars: 200}
	chatHandler := Chat{Service: service.Chat{LLMClient: &myCharaTestLLM{}, Usage: usage}}
	speechHandler := TextToSpeech{Service: service.TextToSpeech{
		Client: &myCharaTestTTS{}, Voice: tts.Voice{Model: "configured-model"}, Usage: usage,
	}}
	e := echo.New()
	e.POST("/chat", chatHandler.ChatPost)
	e.POST("/tts", speechHandler.TextToSpeechPost)
	for _, tc := range []struct {
		name, path, body string
		status           int
		writes           int64
	}{
		{"通常キャラの人格は上書きしない", "/chat", `{"charaID":"com.charalarm.official","myChara":{"name":"名前","personality":"優しい"},"messages":[{"role":"user","content":"おはよう"}]}`, http.StatusBadRequest, 0},
		{"一覧外の声で利用量を増やさない", "/tts", `{"charaID":"com.charalarm.preset.test","voiceID":"voice_private","text":"おはよう"}`, http.StatusBadRequest, 0},
		{"通常キャラの声は上書きしない", "/tts", `{"charaID":"com.charalarm.official","voiceID":"Kore","text":"おはよう"}`, http.StatusBadRequest, 0},
		{"有効な会話は数える", "/chat", `{"charaID":"com.charalarm.preset.test","myChara":{"name":"名前","personality":"優しい"},"messages":[{"role":"user","content":"おはよう"}]}`, http.StatusOK, 1},
		{"有効な音声合成は数える", "/tts", `{"charaID":"com.charalarm.preset.test","voiceID":"Kore","text":"おはよう"}`, http.StatusOK, 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			usageWrites.Store(0)
			req := httptest.NewRequest(http.MethodPost, tc.path, strings.NewReader(tc.body))
			req.Header.Set("Content-Type", "application/json")
			req.SetBasicAuth(myCharaTestUser, myCharaTestToken)
			response := httptest.NewRecorder()
			e.ServeHTTP(response, req)
			require.Equal(t, tc.status, response.Code, response.Body.String())
			require.Equal(t, tc.writes, usageWrites.Load(), "rejected settings must not consume the daily allowance")
		})
	}
}
