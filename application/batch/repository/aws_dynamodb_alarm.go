package repository

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/takoikatakotako/charalarm-batch/database"
	"time"
)

func (a *AWS) QueryByAlarmTime(hour int, minute int, weekday time.Weekday) ([]database.Alarm, error) {
	alarmTime := fmt.Sprintf("%02d-%02d", hour, minute)

	// clientの作成
	client, err := a.createDynamoDBClient()
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
