package repository

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/takoikatakotako/charalarm/worker/entity"
)

const (
	LocalstackEndpoint             = "http://localhost:4566"
	iOSPushPlatformApplication     = "ios-push-platform-application"
	iOSVoIPPushPlatformApplication = "ios-voip-push-platform-application"
)

// Private Methods
func (a *AWS) createSNSClient() (*sns.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}

	// Localの場合
	if a.Profile == "local" {
		return sns.NewFromConfig(cfg, func(o *sns.Options) {
			o.BaseEndpoint = aws.String(LocalstackEndpoint)
		}), nil
	}
	return sns.NewFromConfig(cfg), nil
}

// PublishPlatformApplication VoIPのプッシュ通知をする
func (a *AWS) PublishPlatformApplication(targetArn string, message entity.IOSVoIPPushSNSMessage) error {
	client, err := a.createSNSClient()
	if err != nil {
		return err
	}

	// Encode
	jsonBytes, err := json.Marshal(message)
	if err != nil {
		return err
	}

	// プッシュ通知を発火
	publishInput := &sns.PublishInput{
		Message:   aws.String(string(jsonBytes)),
		TargetArn: aws.String(targetArn),
	}
	_, err = client.Publish(context.Background(), publishInput)
	if err != nil {
		return err
	}

	return nil
}

// SendMessageToDeadLetter エラーのあるメッセージをデッドレターに送信
func (a *AWS) SendMessageToDeadLetter(messageBody string) error {
	// キューに送信
	return a.SendMessageToVoIPPushDeadLetterQueue(messageBody)
}

func (a *AWS) CheckPlatformEndpointEnabled(endpoint string) error {
	client, err := a.createSNSClient()
	if err != nil {
		return err
	}

	// エンドポイントを取得
	getEndpointAttributesInput := &sns.GetEndpointAttributesInput{
		EndpointArn: aws.String(endpoint),
	}
	getEndpointAttributesOutput, err := client.GetEndpointAttributes(context.Background(), getEndpointAttributesInput)
	if err != nil {
		return err
	}

	isEnabled := getEndpointAttributesOutput.Attributes["Enabled"]
	if isEnabled == "False" || isEnabled == "false" {
		return errors.New("EndpointがFalse")
	}
	return nil
}
