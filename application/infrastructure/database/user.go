package database

import (
	"errors"
	"github.com/takoikatakotako/charalarm/common"
	"time"
)

const (
	UserTableName            = "user-table"
	UserTableUserId          = "userID"
	UserTableUserIdIndexName = "user-id-index"
	UserTablePremiumPlan     = "premiumPlan"
)

type User struct {
	UserID      string `dynamodbav:"userID"`
	AuthToken   string `dynamodbav:"authToken"`
	Platform    string `dynamodbav:"platform"`
	PremiumPlan bool   `dynamodbav:"premiumPlan"`

	CreatedAt           string `dynamodbav:"createdAt"`
	UpdatedAt           string `dynamodbav:"updatedAt"`
	RegisteredIPAddress string `dynamodbav:"registeredIPAddress"`

	IOSPlatformInfo UserIOSPlatformInfo `dynamodbav:"iosPlatformInfo"`
}

type UserIOSPlatformInfo struct {
	PushToken                string `dynamodbav:"pushToken"`
	PushTokenSNSEndpoint     string `dynamodbav:"pushTokenSNSEndpoint"`
	VoIPPushToken            string `dynamodbav:"voIPPushToken"`
	VoIPPushTokenSNSEndpoint string `dynamodbav:"voIPPushTokenSNSEndpoint"`
}

func ValidateUser(user User) error {
	// UserID
	if !IsValidUUID(user.UserID) {
		return errors.New(common.ErrorInvalidValue + ": UserID")
	}

	// AuthToken
	if !IsValidUUID(user.AuthToken) {
		return errors.New(common.ErrorInvalidValue + ": AuthToken")
	}

	// Platform
	if user.Platform == "iOS" {
		// Nothing
	} else {
		return errors.New(common.ErrorInvalidValue + ": Platform")
	}

	// CreatedAt
	_, err := time.Parse(
		time.RFC3339,
		user.CreatedAt)
	if err != nil {
		return errors.New(common.ErrorInvalidValue + ": CreatedAt")
	}

	// UpdatedAt
	_, err = time.Parse(
		time.RFC3339,
		user.UpdatedAt)
	if err != nil {
		return errors.New(common.ErrorInvalidValue + ": UpdatedAt")
	}

	// RegisteredIPAddress
	if user.RegisteredIPAddress == "" {
		return errors.New(common.ErrorInvalidValue + ": RegisteredIPAddress")
	}

	// IOSPlatformInfo
	return user.IOSPlatformInfo.Validate()
}

func (u *UserIOSPlatformInfo) Validate() error {
	// PushTokenが空文字の場合はPushTokenSNSEndpointも空文字
	if u.PushToken == "" && u.PushTokenSNSEndpoint != "" {
		return errors.New(common.ErrorInvalidValue + ": PushToken or PushTokenSNSEndpoint")
	}

	// PushTokenSNSEndpointが空文字の場合はPushTokenも空文字
	if u.PushTokenSNSEndpoint == "" && u.PushToken != "" {
		return errors.New(common.ErrorInvalidValue + ": PushToken or PushTokenSNSEndpoint")
	}

	// VoIPPushTokenが空文字の場合はVoIPPushTokenSNSEndpointも空文字
	if u.VoIPPushToken == "" && u.VoIPPushTokenSNSEndpoint != "" {
		return errors.New(common.ErrorInvalidValue + ": VoIPPushToken or VoIPPushTokenSNSEndpoint")
	}

	// VoIPPushTokenSNSEndpointが空文字の場合はVoIPPushTokenも空文字
	if u.VoIPPushTokenSNSEndpoint == "" && u.VoIPPushToken != "" {
		return errors.New(common.ErrorInvalidValue + ": VoIPPushToken or VoIPPushTokenSNSEndpoint")
	}

	return nil
}
