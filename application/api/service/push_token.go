package service

import (
	"errors"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/sns"
	"github.com/takoikatakotako/charalarm-backend/util/message"
)

type PushTokenService struct {
	DynamoDBRepository dynamodb.DynamoDBRepositoryInterface
	SNSRepository      sns.SNSRepositoryInterface
}

func (s *PushTokenService) AddIOSPushToken(userID string, authToken string, pushToken string) error {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		// Nothing
	} else {
		return errors.New(message.ErrorAuthenticationFailure)
	}

	// 既に作成されてるか確認
	if user.IOSPlatformInfo.PushToken == pushToken {
		return nil
	}

	// PlatformApplicationを作成
	snsEndpointArn, err := s.SNSRepository.CreateIOSPushPlatformEndpoint(pushToken)
	if err != nil {
		return err
	}

	// DynamoDBに追加
	user.IOSPlatformInfo.PushToken = pushToken
	user.IOSPlatformInfo.PushTokenSNSEndpoint = snsEndpointArn
	return s.DynamoDBRepository.InsertUser(user)
}

func (s *PushTokenService) AddIOSVoipPushToken(userID string, authToken string, voIPPushToken string) error {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		// Nothing
	} else {
		return errors.New(message.ErrorAuthenticationFailure)
	}

	// 既に作成されてるか確認
	if user.IOSPlatformInfo.VoIPPushToken == voIPPushToken {
		return nil
	}

	// PlatformApplicationを作成
	snsEndpointArn, err := s.SNSRepository.CreateIOSVoipPushPlatformEndpoint(voIPPushToken)
	if err != nil {
		return err
	}

	// DynamoDBに追加
	user.IOSPlatformInfo.VoIPPushToken = voIPPushToken
	user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint = snsEndpointArn
	return s.DynamoDBRepository.InsertUser(user)
}
