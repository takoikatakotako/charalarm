package dynamodb

import (
	"context"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"github.com/takoikatakotako/charalarm-backend/util/validator"
	// "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	// "github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	// charalarm_config "github.com/takoikatakotako/charalarm-backend/config"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	// "math/rand"
	// "time"
)

// GetUser Userを取得する
func (d *DynamoDBRepository) GetUser(userID string) (database.User, error) {
	ctx := context.Background()

	client, err := d.createDynamoDBClient()
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
		return database.User{}, errors.New(message.InvalidValue)
	}

	err = attributevalue.UnmarshalMap(output.Item, &getUser)
	if err != nil {
		return database.User{}, err
	}

	return getUser, nil
}

func (d *DynamoDBRepository) IsExistUser(userID string) (bool, error) {
	// DBClient作成
	client, err := d.createDynamoDBClient()
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

func (d *DynamoDBRepository) InsertUser(user database.User) error {
	// Validate User
	err := validator.ValidateUser(user)
	if err != nil {
		return err
	}

	// 新規レコードの追加
	ctx := context.Background()
	client, err := d.createDynamoDBClient()
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

func (d *DynamoDBRepository) UpdateUserPremiumPlan(userID string, enablePremiumPlan bool) error {
	client, err := d.createDynamoDBClient()
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

func (d *DynamoDBRepository) DeleteUser(userID string) error {
	client, err := d.createDynamoDBClient()
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
