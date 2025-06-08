package output

type UserInfo struct {
	UserID          string
	AuthToken       string
	Platform        string
	PremiumPlan     bool
	IOSPlatformInfo IOSPlatformInfo
}

type IOSPlatformInfo struct {
	PushToken                string
	PushTokenSNSEndpoint     string
	VoIPPushToken            string
	VoIPPushTokenSNSEndpoint string
}
