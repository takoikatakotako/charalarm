package repository

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/google/uuid"
	"github.com/takoikatakotako/charalarm/repository/entity"
)

// 追加したアラームをアラームタイムで検索できる
// * 現在時刻を使っているため、1分以内にテストを実行すると失敗するので注意
//func TestInsertAndQueryByAlarmTime(t *testing.T) {
//	repository := AWS{Profile: "local"}
//
//	// 現在時刻取得
//	currentTime := time.Now()
//	hour := currentTime.Hour()
//	minute := currentTime.Minute()
//	weekday := currentTime.Weekday()
//
//	// Create Alarms
//	alarm0 := createAlarm()
//	alarm0.Hour = hour
//	alarm0.Minute = minute
//	alarm0.SetAlarmTime()
//
//	alarm1 := createAlarm()
//	alarm1.Hour = hour
//	alarm1.Minute = minute
//	alarm1.SetAlarmTime()
//
//	alarm2 := createAlarm()
//	alarm2.Hour = hour
//	alarm2.Minute = minute
//	alarm2.SetAlarmTime()
//
//	// Insert Alarms
//	err := insertAlarm(alarm0)
//	err = insertAlarm(alarm1)
//	err = insertAlarm(alarm2)
//	if err != nil {
//		t.Errorf("unexpected error: %v", err)
//	}
//
//	// Query
//	alarmList, err := repository.QueryByAlarmTime(hour, minute, weekday)
//	if err != nil {
//		t.Errorf("unexpected error: %v", err)
//	}
//
//	// Assert
//	assert.Equal(t, len(alarmList), 3)
//}

func createAlarm() entity.Alarm {
	return entity.Alarm{
		AlarmID: uuid.New().String(),
		UserID:  uuid.New().String(),
		Type:    "IOS_VOIP_PUSH_NOTIFICATION",
		Target:  "target",

		Enable:         true,
		Name:           "My Alarm",
		Hour:           8,
		Minute:         15,
		Time:           "08-15",
		TimeDifference: 0,

		Sunday:    true,
		Monday:    true,
		Tuesday:   true,
		Wednesday: true,
		Thursday:  true,
		Friday:    true,
		Saturday:  true,
	}
}

func insertAlarm(alarm entity.Alarm) error {
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion("ap-northeast-1"))
	if err != nil {
		return err
	}
	client := dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
		o.BaseEndpoint = aws.String(LocalstackEndpoint)
	})

	// 新規レコードの追加
	av, err := attributevalue.MarshalMap(alarm)
	if err != nil {
		fmt.Printf("dynamodb marshal: %s\n", err.Error())
		return err
	}
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(entity.AlarmTableName),
		Item:      av,
	})
	if err != nil {
		return err
	}

	return nil
}
