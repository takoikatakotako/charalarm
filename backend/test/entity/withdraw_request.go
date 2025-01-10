package entity

type WithdrawRequest struct {
	UserID    string `json:"userID"`
	AuthToken string `json:"authToken"`
}
