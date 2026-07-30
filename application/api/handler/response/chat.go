package response

// Chat は /chat のレスポンス。message はずんだもんの応答テキスト。
type Chat struct {
	Message string `json:"message"`
}
