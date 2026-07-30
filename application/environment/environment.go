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
