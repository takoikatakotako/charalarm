package llm

import "context"

// Role はチャットメッセージの役割。
type Role string

const (
	RoleSystem    Role = "system"
	RoleUser      Role = "user"
	RoleAssistant Role = "assistant"
	// RoleTool は道具の結果。ToolCallID で、どの呼び出しの結果かを示す。
	RoleTool Role = "tool"
)

// Message はプロバイダ非依存のチャットメッセージ。
type Message struct {
	Role    Role   `json:"role"`
	Content string `json:"content"`
	// ToolCalls は assistant が道具を呼んだときの呼び出し。
	ToolCalls []ToolCall `json:"toolCalls,omitempty"`
	// ToolCallID は role が tool のとき、どの呼び出しの結果か。
	ToolCallID string `json:"toolCallID,omitempty"`
}

// Tool は LLM に渡す道具 (function calling) の定義。
type Tool struct {
	Name        string
	Description string
	// Parameters は引数の JSON Schema。引数がなければ nil。
	Parameters map[string]any
}

// ToolCall は LLM が求めた道具の呼び出し。
type ToolCall struct {
	ID        string         `json:"id"`
	Name      string         `json:"name"`
	Arguments map[string]any `json:"arguments"`
	// Signature はモデルの思考の署名 (Gemini 3 の thought signature)。
	// 呼び出しを履歴に入れて送り返すとき、そのまま付けないとエラーになる。
	Signature string `json:"signature,omitempty"`
}

// Result は道具つきの問い合わせの結果。ToolCalls があれば道具を呼びたい (Text はそのときのひとこと)。
type Result struct {
	Text      string
	ToolCalls []ToolCall
}

// Client はプロバイダ非依存のチャット補完クライアント。
// OpenAI 以外へ差し替えたい場合はこのインターフェースを実装し、
// NewClient のスイッチに追加する。
type Client interface {
	Chat(ctx context.Context, messages []Message) (string, error)
}

// ToolClient は道具 (function calling) を使えるクライアント。今は Gemini だけ。
type ToolClient interface {
	ChatWithTools(ctx context.Context, messages []Message, tools []Tool) (Result, error)
}

// NewClient は provider に応じた Client を返す（未知の値は OpenAI にフォールバック）。
// gemini は認証つきの HTTP クライアントが要るので、main で NewGeminiClient を使う。
func NewClient(provider string, apiKey string, model string) Client {
	switch provider {
	// case "anthropic":
	// 	return NewAnthropicClient(apiKey, model)
	default:
		return NewOpenAIClient(apiKey, model)
	}
}
