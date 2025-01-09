package entity

type PushToken struct {
	Token          string `json:"token"`
	SNSEndpointArn string `json:"snsEndpointArn"`
}
