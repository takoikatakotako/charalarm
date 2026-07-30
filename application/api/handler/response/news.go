package response

// News はアプリ向けのお知らせレスポンス。
type News struct {
	NewsID       string `json:"newsId"`
	Title        string `json:"title"`
	Body         string `json:"body"`
	RegisteredAt string `json:"registeredAt"`
}
