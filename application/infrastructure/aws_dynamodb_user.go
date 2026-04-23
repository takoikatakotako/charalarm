package infrastructure

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// ScanUsers ユーザーをScanで取得する (管理画面用)
// cursor は LastEvaluatedKey の userID を base64 エンコードしたもの
func (a *AWS) ScanUsers(limit int, cursor string) ([]database.User, string, error) {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return nil, "", err
	}

	scanInput := &dynamodb.ScanInput{
		TableName: aws.String(database.UserTableName),
		Limit:     aws.Int32(int32(limit)),
	}

	if cursor != "" {
		decoded, err := base64.URLEncoding.DecodeString(cursor)
		if err != nil {
			return nil, "", fmt.Errorf("invalid cursor: %w", err)
		}
		scanInput.ExclusiveStartKey = map[string]types.AttributeValue{
			database.UserTableUserId: &types.AttributeValueMemberS{
				Value: string(decoded),
			},
		}
	}

	ctx := context.Background()
	output, err := client.Scan(ctx, scanInput)
	if err != nil {
		return nil, "", err
	}

	users := make([]database.User, 0, len(output.Items))
	for _, item := range output.Items {
		user := database.User{}
		if err := attributevalue.UnmarshalMap(item, &user); err != nil {
			continue
		}
		users = append(users, user)
	}

	nextCursor := ""
	if last, ok := output.LastEvaluatedKey[database.UserTableUserId]; ok {
		if v, ok := last.(*types.AttributeValueMemberS); ok {
			nextCursor = base64.URLEncoding.EncodeToString([]byte(v.Value))
		}
	}

	return users, nextCursor, nil
}

// GetUser Userを取得する
func (a *AWS) GetUser(userID string) (database.User, error) {
	ctx := context.Background()

	client, err := a.createDynamoDBClient()
	if err != nil {
		return database.User{}, err
	}

	// 既存レコードの取得
	getInput := &dynamodb.GetItemInput{
		TableName: aws.String(database.UserTableName),
		Key: map[string]types.AttributeValue{
			database.UserTableUserId: &types.AttributeValueMemberS{
				Value: userID,
			},
		},
	}

	// 取得
	output, err := client.GetItem(ctx, getInput)
	if err != nil {
		return database.User{}, err
	}
	getUser := database.User{}

	if len(output.Item) == 0 {
		return database.User{}, errors.New(common.InvalidValue)
	}

	err = attributevalue.UnmarshalMap(output.Item, &getUser)
	if err != nil {
		return database.User{}, err
	}

	return getUser, nil
}

func (a *AWS) IsExistUser(userID string) (bool, error) {
	// DBClient作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return false, err
	}

	// 既存レコードの取得
	getInput := &dynamodb.GetItemInput{
		TableName: aws.String(database.UserTableName),
		Key: map[string]types.AttributeValue{
			database.UserTableUserId: &types.AttributeValueMemberS{
				Value: userID,
			},
		},
	}
	ctx := context.Background()
	response, err := client.GetItem(ctx, getInput)
	if err != nil {
		return false, err
	}

	if len(response.Item) == 0 {
		return false, nil
	} else {
		return true, nil
	}
}

func (a *AWS) InsertUser(user database.User) error {
	// Validate User
	err := database.ValidateUser(user)
	if err != nil {
		return err
	}

	// 新規レコードの追加
	ctx := context.Background()
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	av, err := attributevalue.MarshalMap(user)
	if err != nil {
		fmt.Printf("dynamodb marshal: %s\n", err.Error())
		return err
	}
	_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(database.UserTableName),
		Item:      av,
	})
	if err != nil {
		fmt.Printf("put item: %s\n", err.Error())
		return err
	}

	return nil
}

func (a *AWS) UpdateUserPremiumPlan(userID string, enablePremiumPlan bool) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	update := expression.UpdateBuilder{}.Set(expression.Name(database.UserTablePremiumPlan), expression.Value(enablePremiumPlan))
	expr, err := expression.NewBuilder().WithUpdate(update).Build()
	if err != nil {
		fmt.Printf("build update expression: %s\n", err.Error())
		return nil
	}
	updateInput := &dynamodb.UpdateItemInput{
		TableName: aws.String(database.UserTableName),
		Key: map[string]types.AttributeValue{
			database.UserTableUserId: &types.AttributeValueMemberS{
				Value: userID,
			},
		},
		// This block can get really out of hand on big updates
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		UpdateExpression:          expr.Update(),
	}

	ctx := context.Background()
	_, err = client.UpdateItem(ctx, updateInput)
	if err != nil {
		fmt.Printf("update item: %s\n", err.Error())
		return err
	}
	return nil
}

func (a *AWS) DeleteUser(userID string) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	deleteInput := &dynamodb.DeleteItemInput{
		TableName: aws.String(database.UserTableName),
		Key: map[string]types.AttributeValue{
			database.UserTableUserId: &types.AttributeValueMemberS{
				Value: userID,
			},
		},
	}

	ctx := context.Background()
	_, err = client.DeleteItem(ctx, deleteInput)
	if err != nil {
		return err
	}

	return nil
}
