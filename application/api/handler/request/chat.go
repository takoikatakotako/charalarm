package request

// ChatMessage は会話の1メッセージ (role: system/user/assistant)。
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// Chat は /chat のリクエストボディ。
// CharaID を指定すると、そのキャラの人格プロンプトをサーバ側で先頭に付与する。
type Chat struct {
	CharaID  string        `json:"charaID"`
	Messages []ChatMessage `json:"messages"`
}
