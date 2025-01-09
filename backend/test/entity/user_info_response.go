package entity

type UserInfoResponse struct {
	UserID           string    `json:"userID"`
	AuthToken        string    `json:"authToken"`
	IOSPushToken     PushToken `json:"iosPushToken"`
	IOSVoIPPushToken PushToken `json:"iosVoIPPushToken"`
}
