package llm

import "context"

// Role はチャットメッセージの役割。
type Role string

const (
	RoleSystem    Role = "system"
	RoleUser      Role = "user"
	RoleAssistant Role = "assistant"
)

// Message はプロバイダ非依存のチャットメッセージ。
type Message struct {
	Role    Role   `json:"role"`
	Content string `json:"content"`
}

// Client はプロバイダ非依存のチャット補完クライアント。
// OpenAI 以外へ差し替えたい場合はこのインターフェースを実装し、
// NewClient のスイッチに追加する。
type Client interface {
	Chat(ctx context.Context, messages []Message) (string, error)
}

// NewClient は provider に応じた Client を返す（未知の値は OpenAI にフォールバック）。
func NewClient(provider string, apiKey string, model string) Client {
	switch provider {
	// case "anthropic":
	// 	return NewAnthropicClient(apiKey, model)
	default:
		return NewOpenAIClient(apiKey, model)
	}
}
