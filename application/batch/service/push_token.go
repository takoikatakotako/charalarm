package service

import (
	"errors"
	"github.com/takoikatakotako/charalarm-api/repository"
	"github.com/takoikatakotako/charalarm-api/util/message"
)

type PushToken struct {
	AWS repository.AWS
}

func (p *PushToken) AddIOSPushToken(userID string, authToken string, pushToken string) error {
	// ユーザーを取得
	user, err := p.AWS.GetUser(userID)
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
	snsEndpointArn, err := p.AWS.CreateIOSPushPlatformEndpoint(pushToken)
	if err != nil {
		return err
	}

	// DynamoDBに追加
	user.IOSPlatformInfo.PushToken = pushToken
	user.IOSPlatformInfo.PushTokenSNSEndpoint = snsEndpointArn
	return p.AWS.InsertUser(user)
}

func (p *PushToken) AddIOSVoipPushToken(userID string, authToken string, voIPPushToken string) error {
	// ユーザーを取得
	user, err := p.AWS.GetUser(userID)
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
	snsEndpointArn, err := p.AWS.CreateIOSVoipPushPlatformEndpoint(voIPPushToken)
	if err != nil {
		return err
	}

	// DynamoDBに追加
	user.IOSPlatformInfo.VoIPPushToken = voIPPushToken
	user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint = snsEndpointArn
	return p.AWS.InsertUser(user)
}
