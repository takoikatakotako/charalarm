package response

type UserInfoResponse struct {
	UserID          string                  `json:"userID"`
	AuthToken       string                  `json:"authToken"`
	Platform        string                  `json:"platform"`
	PremiumPlan     bool                    `json:"premiumPlan"`
	IOSPlatformInfo IOSPlatformInfoResponse `json:"iOSPlatformInfo"`
}
