package repository2

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
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
