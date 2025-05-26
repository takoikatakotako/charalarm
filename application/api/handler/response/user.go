package response

type UserInfo struct {
	UserID          string          `json:"userID"`
	AuthToken       string          `json:"authToken"`
	Platform        string          `json:"platform"`
	PremiumPlan     bool            `json:"premiumPlan"`
	IOSPlatformInfo IOSPlatformInfo `json:"iOSPlatformInfo"`
}

type IOSPlatformInfo struct {
	PushToken                string `json:"pushToken"`
	PushTokenSNSEndpoint     string `json:"pushTokenSNSEndpoint"`
	VoIPPushToken            string `json:"voIPPushToken"`
	VoIPPushTokenSNSEndpoint string `json:"voIPPushTokenSNSEndpoint"`
}
