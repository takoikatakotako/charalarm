package repository

import (
	"context"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/takoikatakotako/charalarm-worker/entity"
)

// Private Methods
func (a *AWS) createSNSClient() (*sns.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}
	return sns.NewFromConfig(cfg), nil
}

// PublishPlatformApplication VoIPのプッシュ通知をする
func (a *AWS) PublishPlatformApplication(alarmInfo entity.IOSVoIPPushAlarmInfoSQSMessage) error {
	// エンドポイントが有効か確認
	err := a.CheckPlatformEndpointEnabled(alarmInfo.SNSEndpointArn)
	if err != nil {
		return err
	}

	// 送信用の Message に変換
	iOSVoIPPushSNSMessage := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	iOSVoIPPushSNSMessage.CharaID = alarmInfo.CharaID
	iOSVoIPPushSNSMessage.CharaName = alarmInfo.CharaName
	iOSVoIPPushSNSMessage.VoiceFileURL = alarmInfo.VoiceFileURL

	// メッセージを送信
	return a.PublishPlatformApplication(iOSVoIPPushSNSMessage)
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
