package service

import (
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/sns"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// iOSPushTokenを登録できる
func TestPushTokenService_AddIOSPushToken(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	ipAddress := "127.0.0.1"
	platform := "iOS"
	pushToken := uuid.New().String()

	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.PushToken, pushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.PushTokenSNSEndpoint, "ios-push-platform-application"))
}

// iOSPushTokenを変更できる
func TestPushTokenService_AddIOSPushTokenCanChange(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "127.0.0.1"
	oldPushToken := uuid.New().String()
	newPushToken := uuid.New().String()

	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSPushToken(userID, authToken, oldPushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.PushToken, oldPushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.PushTokenSNSEndpoint, "ios-push-platform-application"))

	oldEndpoint := getUser.IOSPlatformInfo.PushTokenSNSEndpoint

	// トークン更新
	err = pushService.AddIOSPushToken(userID, authToken, newPushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err = userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.PushToken, newPushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.PushTokenSNSEndpoint, "ios-push-platform-application"))
	assert.NotEqual(t, getUser.IOSPlatformInfo.PushTokenSNSEndpoint, oldEndpoint)
	assert.Equal(t, getUser.IOSPlatformInfo.VoIPPushToken, "")
	assert.Equal(t, getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint, "")
}

// iOSPushTokenを複数回更新できる
func TestPushTokenService_AddIOSPushTokenMultiTimes(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "127.0.0.1"
	pushToken := uuid.New().String()
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	err = pushService.AddIOSPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, pushToken, getUser.IOSPlatformInfo.PushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.PushTokenSNSEndpoint, "ios-push-platform-application"))
	assert.Equal(t, "", getUser.IOSPlatformInfo.VoIPPushToken)
	assert.Equal(t, "", getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint)
}

// iOSVoIPPushTokenを登録できる
func TestPushTokenService_AddIOSVoipPushToken(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "127.0.0.1"
	pushToken := uuid.New().String()

	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := dynamoDBRepository.GetUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, "", getUser.IOSPlatformInfo.PushToken)
	assert.Equal(t, "", getUser.IOSPlatformInfo.PushTokenSNSEndpoint)
	assert.Equal(t, pushToken, getUser.IOSPlatformInfo.VoIPPushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint, "ios-voip-push-platform-application"))
}

// iOSVoIPPushTokenを変更できる
func TestPushTokenService_AddIOSVoipPushTokenCanChange(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "127.0.0.1"
	oldPushToken := uuid.New().String()
	newPushToken := uuid.New().String()

	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSVoipPushToken(userID, authToken, oldPushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.VoIPPushToken, oldPushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint, "ios-voip-push-platform-application"))

	oldSNSEndpoint := getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint

	// トークン更新
	err = pushService.AddIOSVoipPushToken(userID, authToken, newPushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err = userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.VoIPPushToken, newPushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint, "ios-voip-push-platform-application"))
	assert.NotEqual(t, oldSNSEndpoint, getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint)
}

// iOSVoIPPushTokenを複数回変更できる
func TestPushTokenService_AddIOSVoipPushTokenMultiChange(t *testing.T) {
	// DynamoDBRepository
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	snsRepository := &sns.SNSRepository{IsLocal: true}

	// Service
	userService := UserService{DynamoDBRepository: dynamoDBRepository}
	pushService := PushTokenService{DynamoDBRepository: dynamoDBRepository, SNSRepository: snsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "127.0.0.1"
	pushToken := uuid.New().String()

	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// トークン作成
	err = pushService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	err = pushService.AddIOSVoipPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, getUser.IOSPlatformInfo.VoIPPushToken, pushToken)
	assert.True(t, strings.Contains(getUser.IOSPlatformInfo.VoIPPushTokenSNSEndpoint, "ios-voip-push-platform-application"))
}
