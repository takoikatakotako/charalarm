package request

// ChatMessage は会話の1メッセージ (role: system/user/assistant/tool)。
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
	// ToolCalls は assistant が端末の道具を呼んだとき (/chat が返した calls をそのまま入れる)。
	ToolCalls []ChatToolCall `json:"toolCalls"`
	// ToolCallID は role が tool のとき、どの呼び出しの結果か。
	ToolCallID string `json:"toolCallID"`
}

// ChatToolCall は道具の呼び出し。signature は /chat が返したものをそのまま送り返す。
type ChatToolCall struct {
	ID        string         `json:"id"`
	Name      string         `json:"name"`
	Arguments map[string]any `json:"arguments"`
	Signature string         `json:"signature"`
}

// ChatContext は端末から渡すその場の情報。
type ChatContext struct {
	// Now は端末の現在時刻 (RFC 3339)。
	Now string `json:"now"`
	// TimeZone は端末のタイムゾーン (例: Asia/Tokyo)。
	TimeZone string `json:"timeZone"`
}

// Chat は /chat のリクエストボディ。
// CharaID を指定すると、そのキャラの人格プロンプトをサーバ側で先頭に付与する。
// Memory は端末に保存してあるキャラごとの記憶 (サーバには保存しない)。
type Chat struct {
	CharaID string `json:"charaID"`
	// Language はユーザーが選んだ会話の言語 ("ja" / "en")。省略すると日本語。キャラが話せなければキャラの言語になる。
	Language string `json:"language"`
	// Capabilities は端末で使える道具 (例: calendar.read)。許可がないものは含めない。
	Capabilities []string      `json:"capabilities"`
	Memory       string        `json:"memory"`
	Context      *ChatContext  `json:"context"`
	Messages     []ChatMessage `json:"messages"`
}
