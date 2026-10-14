package response

// Chat は /chat のレスポンス。message はずんだもんの応答テキスト。
type Chat struct {
	// Type は "message" (返答) か "toolCall" (端末の道具を使ってから呼び直してほしい)。
	Type string `json:"type"`
	// Message は返答。toolCall のときは、道具を使うあいだに話すひとこと (古いアプリも読めるように同じ項目)。
	Message string `json:"message"`
	// Calls は toolCall のときの呼び出し。結果と一緒に messages に足して送り返す。
	Calls []ChatToolCall `json:"calls,omitempty"`
}

// ChatToolCall は端末に頼む道具の呼び出し。signature はそのまま送り返す。
type ChatToolCall struct {
	ID        string         `json:"id"`
	Name      string         `json:"name"`
	Arguments map[string]any `json:"arguments"`
	Signature string         `json:"signature,omitempty"`
}
