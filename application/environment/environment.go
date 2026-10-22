package environment

import (
	"os"
	"strconv"
)

type Environment struct {
	Profile         string
	ResourceBaseURL string
	LLMProvider     string
	LLMModel        string
	// LLMThinkingLevel は Gemini の思考の深さ。OpenAI では使わない。
	LLMThinkingLevel string
	OpenAIAPIKey     string
}

func (e *Environment) SetCharalarmAWSProfile(defaultValue string) {
	e.Profile = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_AWS_PROFILE"); exists {
		e.Profile = val
	}
}

func (e *Environment) SetResourceBaseURL(defaultValue string) {
	e.ResourceBaseURL = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_RESOURCE_BASE_URL"); exists {
		e.ResourceBaseURL = val
	}
}

// SetLLMProvider は会話生成に使う LLM プロバイダ ("openai" など) を設定する。
func (e *Environment) SetLLMProvider(defaultValue string) {
	e.LLMProvider = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_LLM_PROVIDER"); exists {
		e.LLMProvider = val
	}
}

// SetLLMModel は会話生成に使うモデル名を設定する。
func (e *Environment) SetLLMModel(defaultValue string) {
	e.LLMModel = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_LLM_MODEL"); exists {
		e.LLMModel = val
	}
}

// SetOpenAIAPIKey は OpenAI の API キーを設定する。
func (e *Environment) SetOpenAIAPIKey(defaultValue string) {
	e.OpenAIAPIKey = defaultValue
	if val, exists := os.LookupEnv("OPENAI_API_KEY"); exists {
		e.OpenAIAPIKey = val
	}
}

// SetLLMThinkingLevel は Gemini の思考の深さ (例: MINIMAL) を設定する。空なら指定しない。
func (e *Environment) SetLLMThinkingLevel(defaultValue string) {
	e.LLMThinkingLevel = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_LLM_THINKING_LEVEL"); exists {
		e.LLMThinkingLevel = val
	}
}

// GCPEnvironment は Vertex AI (Gemini の会話・TTS) を呼ぶための設定。
type GCPEnvironment struct {
	// Project が空なら Vertex AI は使わない。
	Project string
	// CredentialConfig は Workload Identity 連携の credential config (external_account の JSON)。秘密値は含まない。
	// 空ならアプリケーションのデフォルト認証情報を使う (ローカル用)。
	CredentialConfig string
}

// LoadGCPEnvironment は Vertex AI の設定を環境変数から読む。
func LoadGCPEnvironment() GCPEnvironment {
	return GCPEnvironment{
		Project:          os.Getenv("CHARALARM_GCP_PROJECT"),
		CredentialConfig: os.Getenv("CHARALARM_GCP_CREDENTIAL_CONFIG"),
	}
}

// TTSEnvironment は音声合成 (Gemini TTS) の設定。
type TTSEnvironment struct {
	Model string
	Voice string
}

// LoadTTSEnvironment は音声合成の設定を環境変数から読む。
func LoadTTSEnvironment() TTSEnvironment {
	e := TTSEnvironment{
		Model: "gemini-3.8-flash-tts",
		Voice: "ja-jp-advisor-5",
	}
	if val, exists := os.LookupEnv("CHARALARM_TTS_MODEL"); exists && val != "" {
		e.Model = val
	}
	if val, exists := os.LookupEnv("CHARALARM_TTS_VOICE"); exists && val != "" {
		e.Voice = val
	}
	return e
}

// RevenueCatEnvironment は RevenueCat (課金) の Webhook を受けるための設定。
type RevenueCatEnvironment struct {
	// WebhookAuthorization は RevenueCat の Webhook に設定した Authorization ヘッダの値。空なら Webhook を受けない。
	WebhookAuthorization string
	// EntitlementID はプレミアムプランの Entitlement の ID。
	EntitlementID string
}

// LoadRevenueCatEnvironment は RevenueCat の設定を環境変数から読む。
func LoadRevenueCatEnvironment() RevenueCatEnvironment {
	e := RevenueCatEnvironment{
		WebhookAuthorization: os.Getenv("CHARALARM_REVENUECAT_WEBHOOK_AUTHORIZATION"),
		EntitlementID:        "premium",
	}
	if val, exists := os.LookupEnv("CHARALARM_REVENUECAT_ENTITLEMENT_ID"); exists && val != "" {
		e.EntitlementID = val
	}
	return e
}

// UsageLimitEnvironment は会話と読み上げの1日の上限。費用が膨らみすぎないようにする。
type UsageLimitEnvironment struct {
	DailyChat         int
	DailyTTSChars     int
	PremiumMultiplier int
}

// LoadUsageLimitEnvironment は1日の上限を環境変数から読む。0 にすると数えない。
func LoadUsageLimitEnvironment() UsageLimitEnvironment {
	return UsageLimitEnvironment{
		DailyChat:         intEnv("CHARALARM_DAILY_CHAT_LIMIT", 60),
		DailyTTSChars:     intEnv("CHARALARM_DAILY_TTS_CHARS_LIMIT", 3000),
		PremiumMultiplier: intEnv("CHARALARM_PREMIUM_LIMIT_MULTIPLIER", 3),
	}
}

func intEnv(key string, defaultValue int) int {
	val, exists := os.LookupEnv(key)
	if !exists || val == "" {
		return defaultValue
	}
	n, err := strconv.Atoi(val)
	if err != nil {
		return defaultValue
	}
	return n
}
