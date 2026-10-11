package request

// ChatMessage は会話の1メッセージ (role: system/user/assistant)。
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
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
	CharaID  string        `json:"charaID"`
	Memory   string        `json:"memory"`
	Context  *ChatContext  `json:"context"`
	Messages []ChatMessage `json:"messages"`
}
