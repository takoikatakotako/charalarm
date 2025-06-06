package infrastructure

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"testing"
	"time"
)

func TestDynamoDBRepository_InsertAlarm(t *testing.T) {
	// DynamoDBRepository
	repository := AWS{Profile: "local"}

	insertAlarm := createAlarm()
	userID := insertAlarm.UserID

	// Insert
	err := repository.InsertAlarm(insertAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err := repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(alarmList), 1)
	assert.Equal(t, alarmList[0], insertAlarm)
}

// 追加したアラームをアラームタイムで検索できる
// * 現在時刻を使っているため、1分以内にテストを実行すると失敗するので注意
func TestInsertAndQueryByAlarmTime(t *testing.T) {
	repository := AWS{Profile: "local"}

	// 現在時刻取得
	currentTime := time.Now()
	hour := currentTime.Hour()
	minute := currentTime.Minute()
	weekday := currentTime.Weekday()

	// Create Alarms
	alarm0 := createAlarm()
	alarm0.Hour = hour
	alarm0.Minute = minute
	alarm0.SetAlarmTime()

	alarm1 := createAlarm()
	alarm1.Hour = hour
	alarm1.Minute = minute
	alarm1.SetAlarmTime()

	alarm2 := createAlarm()
	alarm2.Hour = hour
	alarm2.Minute = minute
	alarm2.SetAlarmTime()

	// Insert Alarms
	err := insertAlarm(alarm0)
	err = insertAlarm(alarm1)
	err = insertAlarm(alarm2)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Query
	alarmList, err := repository.QueryByAlarmTime(hour, minute, weekday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, 3, len(alarmList))
}

// 追加したアラームを更新できる
func TestInsertAndUpdate(t *testing.T) {
	repository := AWS{Profile: "local"}

	alarm := createAlarm()
	userID := alarm.UserID
	newAlarmName := "Updated Alarm"

	// Insert
	err := repository.InsertAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Update
	alarm.Name = newAlarmName
	err = repository.UpdateAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err := repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	updatedAlarm := alarmList[0]

	// Assert
	assert.Equal(t, updatedAlarm.Name, newAlarmName)
}

// 追加したアラームを削除できる
func TestInsertAndDelete(t *testing.T) {
	repository := AWS{Profile: "local"}

	alarm := createAlarm()
	alarmID := alarm.AlarmID
	userID := alarm.UserID

	// Insert
	err := repository.InsertAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err := repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(alarmList), 1)
	assert.Equal(t, alarmList[0], alarm)

	// Delete
	err = repository.DeleteAlarm(alarmID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err = repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// // Assert
	assert.Equal(t, len(alarmList), 0)
}

// 複数のユーザーが作成したアラームを削除できる
func TestAWS_DeleteAlarmByTarget(t *testing.T) {
	repository := AWS{Profile: "local"}

	firstUserID := uuid.New().String()
	secondUserID := uuid.New().String()

	firstUserAlarm := createAlarm()
	firstUserAlarm.UserID = firstUserID

	secondUserAlarm := createAlarm()
	secondUserAlarm.UserID = secondUserID

	// Insert
	err := repository.InsertAlarm(firstUserAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	err = repository.InsertAlarm(secondUserAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	firstUserAlarmList, err := repository.GetAlarmList(firstUserID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	secondUserAlarmList, err := repository.GetAlarmList(secondUserID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(firstUserAlarmList), 1)
	assert.Equal(t, len(secondUserAlarmList), 1)

	// Delete
	err = repository.DeleteAlarmByTarget("target")
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	deletedFirstUserAlarmList, err := repository.GetAlarmList(firstUserID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	deletedSecondUserAlarmList, err := repository.GetAlarmList(secondUserID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(deletedFirstUserAlarmList), 0)
	assert.Equal(t, len(deletedSecondUserAlarmList), 0)
}

func TestInsertAndDeleteAlarmList(t *testing.T) {
	repository := AWS{Profile: "local"}

	userID := uuid.New().String()

	alarm1 := createAlarm()
	alarm1.UserID = userID

	alarm2 := createAlarm()
	alarm2.UserID = userID

	alarm3 := createAlarm()
	alarm3.UserID = userID

	// Insert
	err := repository.InsertAlarm(alarm1)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	err = repository.InsertAlarm(alarm2)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	err = repository.InsertAlarm(alarm3)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err := repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(alarmList), 3)

	// Delete
	err = repository.DeleteUserAlarm(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	alarmList, err = repository.GetAlarmList(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, len(alarmList), 0)
}

func createAlarm() database.Alarm {
	return database.Alarm{
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

func insertAlarm(alarm database.Alarm) error {
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
		TableName: aws.String(database.AlarmTableName),
		Item:      av,
	})
	if err != nil {
		return err
	}

	return nil
}
