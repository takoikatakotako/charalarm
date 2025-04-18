package response

type IOSPlatformInfoResponse struct {
	PushToken                string `json:"pushToken"`
	PushTokenSNSEndpoint     string `json:"pushTokenSNSEndpoint"`
	VoIPPushToken            string `json:"voIPPushToken"`
	VoIPPushTokenSNSEndpoint string `json:"voIPPushTokenSNSEndpoint"`
}
