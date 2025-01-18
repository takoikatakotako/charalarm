package repository2

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/takoikatakotako/charalarm-api/entity2/sns2"
	"strings"
)

const (
	iOSPushPlatformApplication     = "ios-push-platform-application"
	iOSVoIPPushPlatformApplication = "ios-voip-push-platform-application"
)

func (a *AWS) createSNSClient() (*sns.Client, error) {
	ctx := context.Background()

	if a.Profile == "" {
		// AWSなどの場合
		// DynamoDB クライアントの生成
		c, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"))
		if err != nil {
			return nil, err
		}
		return sns.NewFromConfig(c), nil
	} else if a.Profile == "Local" {
		// CIなど Local Stack を利用する場合
		c, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"))
		if err != nil {
			return nil, err
		}
		c.EndpointResolverWithOptions = aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			return aws.Endpoint{
				URL:           "http://localhost:4566",
				SigningRegion: "ap-northeast-1",
			}, nil
		})
		if err != nil {
			return nil, err
		}
		return sns.NewFromConfig(c), nil
	} else {
		// プロファイルを利用する場合
		c, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"), config.WithSharedConfigProfile(a.Profile))
		if err != nil {
			return nil, err
		}
		return sns.NewFromConfig(c), nil
	}
}

// DeletePlatformApplicationEndpoint エンドポイントを削除するコードを追加
func (a *AWS) SNSDeletePlatformApplicationEndpoint(endpointArn string) error {
	client, err := a.createSNSClient()
	if err != nil {
		return err
	}

	// プッシュ通知を発火
	input := &sns.DeleteEndpointInput{
		EndpointArn: aws.String(endpointArn),
	}

	_, err = client.DeleteEndpoint(context.Background(), input)
	return err
}

// CreateIOSPushPlatformEndpoint iOS Platform Endpoint
func (a *AWS) CreateIOSPushPlatformEndpoint(pushToken string) (string, error) {
	platformApplicationArn, err := a.getPlatformApplicationARN(iOSPushPlatformApplication)
	if err != nil {
		return "", err
	}
	return a.createPlatformEndpoint(platformApplicationArn, pushToken)
}

// CreateIOSVoipPushPlatformEndpoint iOS Platform Endpoint
func (a *AWS) CreateIOSVoipPushPlatformEndpoint(pushToken string) (string, error) {
	platformApplicationArn, err := a.getPlatformApplicationARN(iOSVoIPPushPlatformApplication)
	if err != nil {
		return "", err
	}
	return a.createPlatformEndpoint(platformApplicationArn, pushToken)
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

func (a *AWS) PublishPlatformApplication(targetArn string, iosVoipPushSNSMessage sns2.IOSVoIPPushSNSMessage) error {
	client, err := a.createSNSClient()
	if err != nil {
		return err
	}

	// Encode
	jsonBytes, err := json.Marshal(iosVoipPushSNSMessage)
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

// DeletePlatformApplicationEndpoint エンドポイントを削除するコードを追加
func (a *AWS) DeletePlatformApplicationEndpoint(endpointArn string) error {
	client, err := a.createSNSClient()
	if err != nil {
		return err
	}

	// プッシュ通知を発火
	input := &sns.DeleteEndpointInput{
		EndpointArn: aws.String(endpointArn),
	}

	_, err = client.DeleteEndpoint(context.Background(), input)
	return err
}

//////////////////////////////
// Private Methods
//////////////////////////////

// getQueueURL QueueのURLを取得する
func (a *AWS) getPlatformApplicationARN(queueName string) (string, error) {
	// SQSClient作成
	client, err := a.createSNSClient()
	if err != nil {
		return "", err
	}

	// PlatformApplication を取得
	input := &sns.ListPlatformApplicationsInput{}
	output, err := client.ListPlatformApplications(context.Background(), input)
	if err != nil {
		return "", err
	}

	for _, platformApplication := range output.PlatformApplications {
		platformApplicationArn := *platformApplication.PlatformApplicationArn
		if strings.Contains(platformApplicationArn, queueName) {
			return platformApplicationArn, nil
		}
	}

	return "", errors.New("platform Application Not Found")
}

func (a *AWS) createPlatformEndpoint(platformApplicationArn string, pushToken string) (string, error) {
	client, err := a.createSNSClient()
	if err != nil {
		return "", err
	}

	// エンドポイント作成
	getInput := &sns.CreatePlatformEndpointInput{
		PlatformApplicationArn: aws.String(platformApplicationArn),
		Token:                  aws.String(pushToken),
	}
	result, err := client.CreatePlatformEndpoint(context.Background(), getInput)
	if err != nil {
		return "", err
	}

	return *result.EndpointArn, nil
}
