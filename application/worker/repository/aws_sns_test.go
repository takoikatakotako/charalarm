package repository

import (
	"context"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/google/uuid"
	"github.com/takoikatakotako/charalarm-worker/entity"
	"strings"
	"testing"
)

// エンドポイントを作成してPublishにする
func TestPublishPlatformApplication(t *testing.T) {
	repository := AWS{Profile: "local"}

	// endpointを作成
	token := uuid.New().String()
	endpointArn, err := createEndpoint(token)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// 詰め替える
	iOSVoIPPushSNSMessage := entity.IOSVoIPPushSNSMessage{}
	iOSVoIPPushSNSMessage.CharaName = "キャラ名"
	iOSVoIPPushSNSMessage.VoiceFileURL = "ファイルPath"

	err = repository.PublishPlatformApplication(endpointArn, iOSVoIPPushSNSMessage)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

func createEndpoint(pushToken string) (endpointArn string, err error) {
	// SQSClient作成
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion("ap-northeast-1"))
	if err != nil {
		return "", err
	}
	client := sns.NewFromConfig(cfg, func(o *sns.Options) {
		o.BaseEndpoint = aws.String(LocalstackEndpoint)
	})

	// PlatformApplication を取得
	input := &sns.ListPlatformApplicationsInput{}
	output, err := client.ListPlatformApplications(context.Background(), input)
	if err != nil {
		return "", err
	}

	platformApplicationArn := ""
	for _, platformApplication := range output.PlatformApplications {
		if strings.Contains(*platformApplication.PlatformApplicationArn, iOSVoIPPushPlatformApplication) {
			platformApplicationArn = *platformApplication.PlatformApplicationArn
		}
	}

	if platformApplicationArn == "" {
		return "", errors.New("xxx")
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
