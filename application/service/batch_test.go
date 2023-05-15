package service

import (
	"encoding/json"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/entity"
	"github.com/takoikatakotako/charalarm-backend/repository"
	"github.com/takoikatakotako/charalarm-backend/request"
	"math/rand"
	"testing"
	"time"
)

func init() {
	// DynamoDBRepository
	sqsRepository := repository.SQSRepository{IsLocal: true}
	_ = sqsRepository.PurgeQueue()
}

func TestBatchService_QueryDynamoDBAndSendMessage(t *testing.T) {
	// キャラが決まっていない && ボイスファイル名も決まっていない

	// DynamoDBRepository
	dynamoDBRepository := &repository.DynamoDBRepository{IsLocal: true}
	environmentVariableRepository := repository.EnvironmentVariableRepository{IsLocal: true}
	sqsRepository := repository.SQSRepository{IsLocal: true}
	snsRepository := repository.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	alarmService := AlarmService{DynamoDBRepository: dynamoDBRepository}
	batchService := BatchService{EnvironmentVariableRepository: environmentVariableRepository, DynamoDBRepository: dynamoDBRepository, SQSRepository: sqsRepository}
	pushTokenService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = pushTokenService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	requestAlarm := request.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		TimeDifference: 0,
		CharaID:        "",
		CharaName:      "",
		VoiceFileName:  "",
		Sunday:         true,
		Monday:         true,
		Tuesday:        true,
		Wednesday:      true,
		Thursday:       true,
		Friday:         true,
		Saturday:       true,
	}

	err = alarmService.AddAlarm(userID, authToken, requestAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに設定
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := sqsRepository.ReceiveAlarmInfoMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.NotEqual(t, "", getAlarmInfo.CharaName)
	assert.NotEqual(t, "", getAlarmInfo.VoiceFileURL)
}

func TestBatchService_QueryDynamoDBAndSendMessage2(t *testing.T) {
	// キャラが決まっている && ボイスファイル名は決まっていない

	// DynamoDBRepository
	dynamoDBRepository := &repository.DynamoDBRepository{IsLocal: true}
	environmentVariableRepository := repository.EnvironmentVariableRepository{IsLocal: true}
	sqsRepository := repository.SQSRepository{IsLocal: true}
	snsRepository := repository.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	alarmService := AlarmService{DynamoDBRepository: dynamoDBRepository}
	batchService := BatchService{EnvironmentVariableRepository: environmentVariableRepository, DynamoDBRepository: dynamoDBRepository, SQSRepository: sqsRepository}
	pushTokenService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = pushTokenService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	requestAlarm := request.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		TimeDifference: 0,
		CharaID:        "com.charalarm.yui",
		CharaName:      "井上結衣",
		VoiceFileName:  "",
		Sunday:         true,
		Monday:         true,
		Tuesday:        true,
		Wednesday:      true,
		Thursday:       true,
		Friday:         true,
		Saturday:       true,
	}

	err = alarmService.AddAlarm(userID, authToken, requestAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに設定
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := sqsRepository.ReceiveAlarmInfoMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.Equal(t, "井上結衣", getAlarmInfo.CharaName)
	assert.NotEqual(t, "", getAlarmInfo.VoiceFileURL)
}

func TestBatchService_QueryDynamoDBAndSendMessage3(t *testing.T) {
	// キャラが決まっている && ボイスファイル名は決まっている

	// DynamoDBRepository
	dynamoDBRepository := &repository.DynamoDBRepository{IsLocal: true}
	environmentVariableRepository := repository.EnvironmentVariableRepository{IsLocal: true}
	sqsRepository := repository.SQSRepository{IsLocal: true}
	snsRepository := repository.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	alarmService := AlarmService{DynamoDBRepository: dynamoDBRepository}
	batchService := BatchService{EnvironmentVariableRepository: environmentVariableRepository, DynamoDBRepository: dynamoDBRepository, SQSRepository: sqsRepository}
	pushTokenService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = pushTokenService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	requestAlarm := request.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		TimeDifference: 0,
		CharaID:        "com.charalarm.yui",
		CharaName:      "井上結衣",
		VoiceFileName:  "com-charalarm-yui-15.caf",
		Sunday:         true,
		Monday:         true,
		Tuesday:        true,
		Wednesday:      true,
		Thursday:       true,
		Friday:         true,
		Saturday:       true,
	}

	err = alarmService.AddAlarm(userID, authToken, requestAlarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに設定
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := sqsRepository.ReceiveAlarmInfoMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.Equal(t, "井上結衣", getAlarmInfo.CharaName)
	assert.Equal(t, "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-15.caf", getAlarmInfo.VoiceFileURL)
}
