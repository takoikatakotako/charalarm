package request

// ChatMessage は会話の1メッセージ (role: system/user/assistant)。
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// Chat は /chat のリクエストボディ。
type Chat struct {
	Messages []ChatMessage `json:"messages"`
}
