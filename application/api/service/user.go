package service

import (
	"errors"
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"time"
)

type User struct {
	AWS infrastructure.AWS
}

func (u *User) GetUser(userID string, authToken string) (output.UserInfo, error) {
	// ユーザーを取得
	user, err := u.AWS.GetUser(userID)
	if err != nil {
		return output.UserInfo{}, err
	}

	// UserID, authTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		return convertTooUserInfoOutput(user), nil
	}

	// 一致しない場合
	return output.UserInfo{}, errors.New(common.AuthenticationFailure)
}

func (u *User) Signup(userID string, authToken string, platform string, ipAddress string) error {
	// バリデーション
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return errors.New(common.ErrorInvalidValue)
	}

	// Check User Is Exist
	isExist, err := u.AWS.IsExistUser(userID)
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
	err = u.AWS.InsertUser(user)
	if err != nil {
		return err
	}

	return nil
}

func (u *User) UpdatePremiumPlan(userID string, authToken string, enablePremiumPlan bool) error {
	// バリデーション
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return errors.New(common.ErrorInvalidValue)
	}

	// Check User Is Exist
	isExist, err := u.AWS.IsExistUser(userID)
	if err != nil {
		return err
	}
	if !isExist {
		return errors.New(common.ErrorInvalidValue)
	}

	// プレミアムプランを更新
	return u.AWS.UpdateUserPremiumPlan(userID, enablePremiumPlan)
}

func (u *User) Withdraw(userID string, authToken string) error {
	// バリデーション
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return errors.New(common.InvalidValue)
	}

	// ユーザーを取得
	user, err := u.AWS.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenの一致を確認
	if user.UserID == userID && user.AuthToken == authToken {
	} else {
		// 認証失敗
		return errors.New(common.ErrorAuthenticationFailure)
	}

	// PlatformEndpointを削除する
	if user.IOSPlatformInfo.PushTokenSNSEndpoint != "" {
		err = u.AWS.SNSDeletePlatformApplicationEndpoint(user.IOSPlatformInfo.PushTokenSNSEndpoint)
		if err != nil {
			return err
		}
	}

	if user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint != "" {
		err = u.AWS.SNSDeletePlatformApplicationEndpoint(user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint)
		if err != nil {
			return err
		}
	}

	return u.AWS.DeleteUser(userID)
}
