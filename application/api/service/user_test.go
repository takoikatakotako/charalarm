package service

import (
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"testing"
)

func TestInfoUser(t *testing.T) {
	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}

	// Service
	userService := User{AWS: awsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	ipAddress := "127.0.0.1"
	platform := "iOS"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, userID, getUser.UserID)
}

func TestSignup(t *testing.T) {
	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}

	// Service
	userService := User{AWS: awsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "0.0.0.0"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// ユーザー取得
	getUser, err := awsRepository.GetUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, userID, getUser.UserID)
	assert.Equal(t, authToken, getUser.AuthToken)
}

func TestUserService_Withdraw(t *testing.T) {
	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}

	// Service
	userService := User{AWS: awsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "0.0.0.0"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// IsExist
	firstIsExist, err := awsRepository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, firstIsExist, true)

	// Withdraw
	err = userService.Withdraw(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// IsExist
	secondIsExist, err := awsRepository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, secondIsExist, false)
}

func TestUserService_WithdrawAndCreateSamePushToken(t *testing.T) {
	// 退会後に別のユーザーが同じ PushTokenでエンドポイントを作れる

	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}

	// Service
	userService := User{AWS: awsRepository}
	pushTokenService := PushToken{AWS: awsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "0.0.0.0"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// エンドポイント作成
	pushToken := uuid.New().String()
	err = pushTokenService.AddIOSPushToken(userID, authToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Withdraw
	err = userService.Withdraw(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// 別ユーザー作成
	newUserID := uuid.New().String()
	newAuthToken := uuid.New().String()
	newPlatform := "iOS"
	newIPAddress := "0.0.0.0"
	err = userService.Signup(newUserID, newAuthToken, newPlatform, newIPAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// PushToken作成
	err = pushTokenService.AddIOSPushToken(newUserID, newAuthToken, pushToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

func TestUserService_UpdatePremiumPlan(t *testing.T) {
	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}

	// Service
	userService := User{AWS: awsRepository}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	platform := "iOS"
	ipAddress := "0.0.0.0"
	err := userService.Signup(userID, authToken, platform, ipAddress)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// プレミアムプランが向こうであることを確認
	userInfoResponse, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, false, userInfoResponse.PremiumPlan)

	// プレミアムプランの有効化
	err = userService.UpdatePremiumPlan(userID, authToken, true)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// プレミアムプランの有効化を確認
	updatedUserInfoResponse, err := userService.GetUser(userID, authToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, true, updatedUserInfoResponse.PremiumPlan)
}
