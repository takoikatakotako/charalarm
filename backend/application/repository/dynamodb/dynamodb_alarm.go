package dynamodb

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/util/validator"
	"time"
)

// IsExistAlarm Alarmが存在するか
func (d *DynamoDBRepository) IsExistAlarm(alarmID string) (bool, error) {
	client, err := d.createDynamoDBClient()
	if err != nil {
		return false, err
	}

	// 既存レコードの取得
	getInput := &dynamodb.GetItemInput{
		TableName: aws.String(database.AlarmTableName),
		Key: map[string]types.AttributeValue{
			database.AlarmTableColumnAlarmID: &types.AttributeValueMemberS{
				Value: alarmID,
			},
		},
	}

	// 取得
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

func (d *DynamoDBRepository) GetAlarmList(userID string) ([]database.Alarm, error) {
	client, err := d.createDynamoDBClient()
	if err != nil {
		return []database.Alarm{}, err
	}

	// クエリ実行
	keyEx := expression.Key(database.AlarmTableColumnUserID).Equal(expression.Value(userID))
	expr, err := expression.NewBuilder().WithKeyCondition(keyEx).Build()
	output, err := client.Query(context.TODO(), &dynamodb.QueryInput{
		TableName:                 aws.String(database.AlarmTableName),
		IndexName:                 aws.String(database.AlarmTableIndexUserID),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		KeyConditionExpression:    expr.KeyCondition(),
	})
	if err != nil {
		return []database.Alarm{}, err
	}

	// 取得結果を struct の配列に変換
	alarmList := make([]database.Alarm, 0)
	for _, item := range output.Items {
		alarm := database.Alarm{}
		err := attributevalue.UnmarshalMap(item, &alarm)
		if err != nil {
			// TODO ログを出す
			continue
		}
		alarmList = append(alarmList, alarm)
	}

	return alarmList, nil
}

func (d *DynamoDBRepository) QueryByAlarmTime(hour int, minute int, weekday time.Weekday) ([]database.Alarm, error) {
	alarmTime := fmt.Sprintf("%02d-%02d", hour, minute)

	// clientの作成
	client, err := d.createDynamoDBClient()
	if err != nil {
		return []database.Alarm{}, err
	}

	keyEx := expression.Key(database.AlarmTableColumnTime).Equal(expression.Value(alarmTime))
	expr, err := expression.NewBuilder().WithKeyCondition(keyEx).Build()

	output, err := client.Query(context.TODO(), &dynamodb.QueryInput{
		TableName:                 aws.String(database.AlarmTableName),
		IndexName:                 aws.String(database.AlarmTableIndexAlarmTime),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		KeyConditionExpression:    expr.KeyCondition(),
	})
	if err != nil {
		return []database.Alarm{}, err
	}

	fmt.Printf("----------------")
	fmt.Printf("Map: %v", output.Items)
	fmt.Printf("----------------")

	// 取得結果を struct の配列に変換
	alarmList := make([]database.Alarm, 0)
	for _, item := range output.Items {
		alarm := database.Alarm{}
		err := attributevalue.UnmarshalMap(item, &alarm)
		if err != nil {
			// TODO ログを出す
			fmt.Printf("----------------")
			fmt.Printf("err, %v", err)
			fmt.Printf("----------------")
			continue
		}

		// 曜日が一致するもの
		switch weekday {
		case time.Sunday:
			if alarm.Sunday {
				alarmList = append(alarmList, alarm)
			}
		case time.Monday:
			if alarm.Monday {
				alarmList = append(alarmList, alarm)
			}
		case time.Tuesday:
			if alarm.Tuesday {
				alarmList = append(alarmList, alarm)
			}
		case time.Wednesday:
			if alarm.Wednesday {
				alarmList = append(alarmList, alarm)
			}
		case time.Thursday:
			if alarm.Thursday {
				alarmList = append(alarmList, alarm)
			}
		case time.Friday:
			if alarm.Friday {
				alarmList = append(alarmList, alarm)
			}
		case time.Saturday:
			if alarm.Saturday {
				alarmList = append(alarmList, alarm)
			}
		}
	}

	return alarmList, nil
}

func (d *DynamoDBRepository) InsertAlarm(alarm database.Alarm) error {
	// Alarm のバリデーション
	err := validator.ValidateAlarm(alarm)
	if err != nil {
		return err
	}

	client, err := d.createDynamoDBClient()
	if err != nil {
		fmt.Printf("err, %v", err)
		return err
	}

	// 新規レコードの追加
	av, err := attributevalue.MarshalMap(alarm)
	if err != nil {
		fmt.Printf("dynamodb marshal: %s\n", err.Error())
		return err
	}
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(database.AlarmTableName),
		Item:      av,
	})
	if err != nil {
		fmt.Printf("put item: %s\n", err.Error())
		return err
	}

	return nil
}

// TODO: 少し危険な方法で更新しているので、更新対象の数だけメソッドを作成する
func (d *DynamoDBRepository) UpdateAlarm(alarm database.Alarm) error {
	// Alarm のバリデーション
	err := validator.ValidateAlarm(alarm)
	if err != nil {
		fmt.Printf("err, %v", err)
		return err
	}

	// レコードを更新する
	client, err := d.createDynamoDBClient()
	if err != nil {
		fmt.Printf("err, %v", err)
		return err
	}

	av, err := attributevalue.MarshalMap(alarm)
	if err != nil {
		fmt.Printf("dynamodb marshal: %s\n", err.Error())
		return err
	}
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(database.AlarmTableName),
		Item:      av,
	})
	if err != nil {
		fmt.Printf("put item: %s\n", err.Error())
		return err
	}

	return nil
}

func (d *DynamoDBRepository) DeleteAlarm(alarmID string) error {
	ctx := context.Background()

	client, err := d.createDynamoDBClient()
	if err != nil {
		return err
	}

	deleteInput := &dynamodb.DeleteItemInput{
		TableName: aws.String(database.AlarmTableName),
		Key: map[string]types.AttributeValue{
			database.AlarmTableColumnAlarmID: &types.AttributeValueMemberS{Value: alarmID},
		},
	}

	_, err = client.DeleteItem(ctx, deleteInput)
	if err != nil {
		return err
	}

	return nil
}

func (d *DynamoDBRepository) DeleteUserAlarm(userID string) error {
	var err error
	var ctx = context.Background()

	client, err := d.createDynamoDBClient()
	if err != nil {
		return err
	}

	// userIDからアラームを検索
	output, err := client.Query(ctx, &dynamodb.QueryInput{
		TableName:              aws.String(database.AlarmTableName),
		IndexName:              aws.String(database.UserTableUserIdIndexName),
		KeyConditionExpression: aws.String("userID = :userID"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":userID": &types.AttributeValueMemberS{Value: userID},
		},
	})
	if err != nil {
		return err
	}

	// 検索結果から一括削除のためのrequestItemsを作成
	requestItems := []types.WriteRequest{}
	for _, item := range output.Items {
		// alarmIDを取得
		alarm := database.Alarm{}
		if err := attributevalue.UnmarshalMap(item, &alarm); err != nil {
			return err
		}
		alarmID := alarm.AlarmID

		// requestItemsを作成
		requestItem := types.WriteRequest{
			DeleteRequest: &types.DeleteRequest{
				Key: map[string]types.AttributeValue{
					database.AlarmTableColumnAlarmID: &types.AttributeValueMemberS{Value: alarmID},
				},
			},
		}
		requestItems = append(requestItems, requestItem)
	}

	// アラームを削除
	_, err = client.BatchWriteItem(ctx, &dynamodb.BatchWriteItemInput{
		RequestItems: map[string][]types.WriteRequest{
			database.AlarmTableName: requestItems,
		},
	})
	if err != nil {
		return err
	}

	return nil
}
