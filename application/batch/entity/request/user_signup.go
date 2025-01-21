package request

type UserSignUp struct {
	UserID    string `json:"userID"`
	AuthToken string `json:"authToken"`
	Platform  string `json:"platform"`
}
