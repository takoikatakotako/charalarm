package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
func (a *AWS) PublishPlatformApplication(targetArn string, message entity.IOSVoIPPushSNSMessage) error {
	//// 送信用の Message に変換
	//iOSVoIPPushSNSMessage := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	//iOSVoIPPushSNSMessage.CharaID = alarmInfo.CharaID
	//iOSVoIPPushSNSMessage.CharaName = alarmInfo.CharaName
	//iOSVoIPPushSNSMessage.VoiceFileURL = alarmInfo.VoiceFileURL
	//
	//// メッセージを送信
	//return a.PublishPlatformApplication(iOSVoIPPushSNSMessage)

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
		fmt.Println("@@@@@@@@@@@")
		fmt.Println("CreateSNSClient Failed")
		fmt.Println(err)
		fmt.Println("@@@@@@@@@@@")
		return err
	}

	// エンドポイントを取得
	getEndpointAttributesInput := &sns.GetEndpointAttributesInput{
		EndpointArn: aws.String(endpoint),
	}
	getEndpointAttributesOutput, err := client.GetEndpointAttributes(context.Background(), getEndpointAttributesInput)
	if err != nil {
		fmt.Println("@@@@@@@@@@@")
		fmt.Println("GetEndpointAttributes Failed")
		fmt.Println(err)
		fmt.Println("@@@@@@@@@@@")
		return err
	}

	fmt.Println("@@@@@@@@@@@")
	fmt.Println("getEndpointAttributesOutput")
	fmt.Println(getEndpointAttributesOutput)
	fmt.Println("@@@@@@@@@@@")

	isEnabled := getEndpointAttributesOutput.Attributes["Enabled"]
	if isEnabled == "False" || isEnabled == "false" {
		return errors.New("EndpointがFalse")
	}

	return nil
}
