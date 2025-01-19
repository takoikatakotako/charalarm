package repository2

import (
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// Private Methods
func (a *AWS) createDynamoDBClient() (*dynamodb.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}
	return dynamodb.NewFromConfig(cfg), nil
}
