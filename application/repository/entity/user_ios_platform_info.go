package entity

type UserIOSPlatformInfo struct {
	PushToken                string `dynamodbav:"pushToken"`
	PushTokenSNSEndpoint     string `dynamodbav:"pushTokenSNSEndpoint"`
	VoIPPushToken            string `dynamodbav:"voIPPushToken"`
	VoIPPushTokenSNSEndpoint string `dynamodbav:"voIPPushTokenSNSEndpoint"`
}
