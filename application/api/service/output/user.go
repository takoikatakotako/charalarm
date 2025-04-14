package output

type UserInfoResponse struct {
	UserID          string
	AuthToken       string
	Platform        string
	PremiumPlan     bool
	IOSPlatformInfo IOSPlatformInfoResponse
}

type IOSPlatformInfoResponse struct {
	PushToken                string
	PushTokenSNSEndpoint     string
	VoIPPushToken            string
	VoIPPushTokenSNSEndpoint string
}
