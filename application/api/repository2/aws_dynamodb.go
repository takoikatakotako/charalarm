package repository2

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// Private Methods
func (a *AWS) createDynamoDBClient() (*dynamodb.Client, error) {
	ctx := context.Background()

	if a.Profile == "" {
		// AWSなどの場合
		// DynamoDB クライアントの生成
		c, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"))
		if err != nil {
			return nil, err
		}
		return dynamodb.NewFromConfig(c), nil
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
	}

	// プロファイルを利用する場合
	c, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"), config.WithSharedConfigProfile(a.Profile))
	if err != nil {
		return nil, err
	}
	return dynamodb.NewFromConfig(c), nil
}
