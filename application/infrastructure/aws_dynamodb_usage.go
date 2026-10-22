package infrastructure

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// AddUsage はその日の使用量を足して、足したあとの値を返す (なければ作る)。
func (a *AWS) AddUsage(usageKey string, chat int, ttsChars int, expiresAt int64) (database.Usage, error) {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return database.Usage{}, err
	}

	update := expression.UpdateBuilder{}.
		Add(expression.Name(database.UsageTableChat), expression.Value(chat)).
		Add(expression.Name(database.UsageTableTTSChars), expression.Value(ttsChars)).
		Set(expression.Name(database.UsageTableExpiresAt), expression.Value(expiresAt))
	expr, err := expression.NewBuilder().WithUpdate(update).Build()
	if err != nil {
		return database.Usage{}, err
	}

	output, err := client.UpdateItem(context.Background(), &dynamodb.UpdateItemInput{
		TableName: aws.String(database.UsageTableName),
		Key: map[string]types.AttributeValue{
			database.UsageTableUsageKey: &types.AttributeValueMemberS{Value: usageKey},
		},
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		UpdateExpression:          expr.Update(),
		ReturnValues:              types.ReturnValueAllNew,
	})
	if err != nil {
		return database.Usage{}, err
	}

	usage := database.Usage{}
	if err := attributevalue.UnmarshalMap(output.Attributes, &usage); err != nil {
		return database.Usage{}, err
	}
	return usage, nil
}
