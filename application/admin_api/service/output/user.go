package output

type User struct {
	UserID              string
	Platform            string
	PremiumPlan         bool
	CreatedAt           string
	UpdatedAt           string
	RegisteredIPAddress string
	IOSPlatformInfo     IOSPlatformInfo
}

type IOSPlatformInfo struct {
	PushToken                string
	PushTokenSNSEndpoint     string
	VoIPPushToken            string
	VoIPPushTokenSNSEndpoint string
}

type ScanUsersResult struct {
	Users      []User
	NextCursor string
}
