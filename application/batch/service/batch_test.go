package service

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"github.com/takoikatakotako/charalarm/infrastructure/queue"
	"math/rand"
	"os"
	"testing"
	"time"
)

func TestMain(m *testing.M) {
	// Before Tests
	repo := infrastructure.AWS{Profile: "local"}
	_ = repo.PurgeQueue()

	exitVal := m.Run()

	// After Tests
	os.Exit(exitVal)
}

func TestBatchService_QueryDynamoDBAndSendMessage_RandomCharaAndRandomVoice(t *testing.T) {
	// キャラが決まっていない && ボイスファイル名も決まっていない

	// DynamoDBRepository
	repo := infrastructure.AWS{Profile: "local"}
	batchService := Batch{
		AWS: repo,
	}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := createUser(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = createPlatformEndpoint(userID, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザーを取得
	user, err := getUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	alarm := database.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Target:         user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint,
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		Time:           fmt.Sprintf("%02d-%02d", hour, minute),
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

	err = createAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに送信
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := receiveMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := queue.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.NotEqual(t, "", getAlarmInfo.CharaName)
	assert.NotEqual(t, "", getAlarmInfo.VoiceFileURL)
}

func TestBatchService_QueryDynamoDBAndSendMessage_DecidedCharaAndRandomVoice(t *testing.T) {
	// キャラが決まっている && ボイスファイル名は決まっていない

	// DynamoDBRepository
	repo := infrastructure.AWS{Profile: "local"}

	// Service
	batchService := Batch{
		AWS: repo,
	}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := createUser(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = createPlatformEndpoint(userID, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザーを取得
	user, err := getUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	alarm := database.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Target:         user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint,
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		Time:           fmt.Sprintf("%02d-%02d", hour, minute),
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

	err = createAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに送信
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := receiveMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Memo たまにエラーになる、他のテストの関係で複数のテストが絡んでいるのかも？

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := queue.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.Equal(t, "井上結衣", getAlarmInfo.CharaName)
	assert.NotEqual(t, "", getAlarmInfo.VoiceFileURL)
}

func TestBatchService_QueryDynamoDBAndSendMessage_DecidedCharaAndDecidedVoice(t *testing.T) {
	// キャラが決まっている && ボイスファイル名は決まっている

	// DynamoDBRepository
	repo := infrastructure.AWS{Profile: "local"}

	// Service
	batchService := Batch{
		AWS:         repo,
		Environment: environment.Environment{ResourceBaseURL: "http://localhost:4566"},
	}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	const ipAddress = "127.0.0.1"
	const platform = "iOS"
	err := createUser(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PlatformEndpointを作成
	pushToken := uuid.New().String()
	err = createPlatformEndpoint(userID, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザーを取得
	user, err := getUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// アラーム追加
	alarmID := uuid.New().String()
	hour := rand.Intn(12)
	minute := rand.Intn(60)
	alarm := database.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           "IOS_VOIP_PUSH_NOTIFICATION",
		Target:         user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint,
		Enable:         true,
		Name:           "Alarm Name",
		Hour:           hour,
		Minute:         minute,
		Time:           fmt.Sprintf("%02d-%02d", hour, minute),
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

	err = createAlarm(alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに設定
	err = batchService.QueryDynamoDBAndSendMessage(hour, minute, time.Sunday)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// SQSに入ったことを確認
	messages, err := receiveMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := queue.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	err = json.Unmarshal([]byte(body), &getAlarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
	assert.Equal(t, "井上結衣", getAlarmInfo.CharaName)
	assert.Equal(t, "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-15.caf", getAlarmInfo.VoiceFileURL)
}

func getUser(userID string) (database.User, error) {
	// ユーザーを取得
	repo := infrastructure.AWS{Profile: "local"}
	return repo.GetUser(userID)
}

func createUser(userID string, authToken string, platform string, ipAddress string) error {
	// ユーザー作成
	repo := infrastructure.AWS{Profile: "local"}
	currentTime := time.Now()
	user := database.User{
		UserID:              userID,
		AuthToken:           authToken,
		Platform:            platform,
		PremiumPlan:         false,
		CreatedAt:           currentTime.Format(time.RFC3339),
		UpdatedAt:           currentTime.Format(time.RFC3339),
		RegisteredIPAddress: ipAddress,
	}
	return repo.InsertUser(user)
}

func createPlatformEndpoint(userID string, pushToken string) error {
	repo := infrastructure.AWS{Profile: "local"}

	// ユーザーを取得
	user, err := repo.GetUser(userID)
	if err != nil {
		return err
	}

	// PlatformApplicationを作成
	snsEndpointArn, err := repo.CreateIOSVoipPushPlatformEndpoint(pushToken)
	if err != nil {
		return err
	}

	// DynamoDBに追加
	user.IOSPlatformInfo.VoIPPushToken = pushToken
	user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint = snsEndpointArn
	return repo.InsertUser(user)
}

func createAlarm(databaseAlarm database.Alarm) error {
	// アラームを追加する
	repo := infrastructure.AWS{Profile: "local"}
	return repo.InsertAlarm(databaseAlarm)
}

func receiveMessage() ([]types.Message, error) {
	repo := infrastructure.AWS{Profile: "local"}
	return repo.ReceiveAlarmInfoMessage()
}
