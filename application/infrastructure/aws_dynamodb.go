package infrastructure

import (
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// Private Methods
func (a *AWS) createDynamoDBClient() (*dynamodb.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}

	// Localの場合
	if a.Profile == "local" {
		return dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
			o.BaseEndpoint = aws.String(LocalstackEndpoint)
		}), nil
	}

	// Local 以外の場合
	return dynamodb.NewFromConfig(cfg), nil
}
