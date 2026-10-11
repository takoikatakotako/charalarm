package environment

import "os"

type Environment struct {
	Profile         string
	ResourceBaseURL string
	LLMProvider     string
	LLMModel        string
	OpenAIAPIKey    string
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

// TTSEnvironment は音声合成 (Vertex AI の Gemini TTS) の設定。
type TTSEnvironment struct {
	// GCPProject が空なら音声合成は無効 (/tts は 503 を返す)。
	GCPProject string
	// GCPCredentialConfig は Workload Identity 連携の credential config (external_account の JSON)。秘密値は含まない。
	// 空ならアプリケーションのデフォルト認証情報を使う (ローカル用)。
	GCPCredentialConfig string
	Model               string
	Voice               string
}

// LoadTTSEnvironment は音声合成の設定を環境変数から読む。
func LoadTTSEnvironment() TTSEnvironment {
	e := TTSEnvironment{
		GCPProject:          os.Getenv("CHARALARM_GCP_PROJECT"),
		GCPCredentialConfig: os.Getenv("CHARALARM_GCP_CREDENTIAL_CONFIG"),
		Model:               "gemini-3.8-flash-tts",
		Voice:               "ja-jp-advisor-5",
	}
	if val, exists := os.LookupEnv("CHARALARM_TTS_MODEL"); exists && val != "" {
		e.Model = val
	}
	if val, exists := os.LookupEnv("CHARALARM_TTS_VOICE"); exists && val != "" {
		e.Voice = val
	}
	return e
}
