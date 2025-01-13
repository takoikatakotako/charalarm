package service

import (
	"errors"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/sns"
	"github.com/takoikatakotako/charalarm-backend/util/converter"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"github.com/takoikatakotako/charalarm-backend/util/validator"
	"time"

	"github.com/takoikatakotako/charalarm-backend/entity/database"
)

type UserService struct {
	DynamoDBRepository dynamodb.DynamoDBRepositoryInterface
	SNSRepository      sns.SNSRepositoryInterface
}

func (s *UserService) GetUser(userID string, authToken string) (response.UserInfoResponse, error) {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return response.UserInfoResponse{}, err
	}

	// UserID, authTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		return converter.DatabaseUserToResponseUserInfo(user), nil
	}

	// 一致しない場合
	return response.UserInfoResponse{}, errors.New(message.AuthenticationFailure)
}

func (s *UserService) Signup(userID string, authToken string, platform string, ipAddress string) error {
	// バリデーション
	if !validator.IsValidUUID(userID) || !validator.IsValidUUID(authToken) {
		return errors.New(message.ErrorInvalidValue)
	}

	// Check User Is Exist
	isExist, err := s.DynamoDBRepository.IsExistUser(userID)
	if err != nil {
		return err
	}

	// ユーザーが既に作成されていた場合
	if isExist {
		return nil
	}

	// ユーザー作成
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
	return s.DynamoDBRepository.InsertUser(user)
}

func (s *UserService) UpdatePremiumPlan(userID string, authToken string, enablePremiumPlan bool) error {
	// バリデーション
	if !validator.IsValidUUID(userID) || !validator.IsValidUUID(authToken) {
		return errors.New(message.ErrorInvalidValue)
	}

	// Check User Is Exist
	isExist, err := s.DynamoDBRepository.IsExistUser(userID)
	if err != nil {
		return err
	}
	if !isExist {
		return errors.New(message.ErrorInvalidValue)
	}

	// プレミアムプランを更新
	return s.DynamoDBRepository.UpdateUserPremiumPlan(userID, enablePremiumPlan)
}

func (s *UserService) Withdraw(userID string, authToken string) error {
	// バリデーション
	if !validator.IsValidUUID(userID) || !validator.IsValidUUID(authToken) {
		return errors.New(message.InvalidValue)
	}

	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenの一致を確認
	if user.UserID == userID && user.AuthToken == authToken {
	} else {
		// 認証失敗
		return errors.New(message.ErrorAuthenticationFailure)
	}

	// PlatformEndpointを削除する
	if user.IOSPlatformInfo.PushTokenSNSEndpoint != "" {
		err = s.SNSRepository.DeletePlatformApplicationEndpoint(user.IOSPlatformInfo.PushTokenSNSEndpoint)
		if err != nil {
			return err
		}
	}

	if user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint != "" {
		err = s.SNSRepository.DeletePlatformApplicationEndpoint(user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint)
		if err != nil {
			return err
		}
	}

	return s.DynamoDBRepository.DeleteUser(userID)
}
