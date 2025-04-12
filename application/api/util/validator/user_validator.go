package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"time"
)

func ValidateUser(user database.User) error {
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
	return ValidateUserIOSPlatformInfo(user.IOSPlatformInfo)
}

func ValidateUserIOSPlatformInfo(userIOSPlatformInfo database.UserIOSPlatformInfo) error {
	// PushTokenが空文字の場合はPushTokenSNSEndpointも空文字
	if userIOSPlatformInfo.PushToken == "" && userIOSPlatformInfo.PushTokenSNSEndpoint != "" {
		return errors.New(common.ErrorInvalidValue + ": PushToken or PushTokenSNSEndpoint")
	}

	// PushTokenSNSEndpointが空文字の場合はPushTokenも空文字
	if userIOSPlatformInfo.PushTokenSNSEndpoint == "" && userIOSPlatformInfo.PushToken != "" {
		return errors.New(common.ErrorInvalidValue + ": PushToken or PushTokenSNSEndpoint")
	}

	// VoIPPushTokenが空文字の場合はVoIPPushTokenSNSEndpointも空文字
	if userIOSPlatformInfo.VoIPPushToken == "" && userIOSPlatformInfo.VoIPPushTokenSNSEndpoint != "" {
		return errors.New(common.ErrorInvalidValue + ": VoIPPushToken or VoIPPushTokenSNSEndpoint")
	}

	// VoIPPushTokenSNSEndpointが空文字の場合はVoIPPushTokenも空文字
	if userIOSPlatformInfo.VoIPPushTokenSNSEndpoint == "" && userIOSPlatformInfo.VoIPPushToken != "" {
		return errors.New(common.ErrorInvalidValue + ": VoIPPushToken or VoIPPushTokenSNSEndpoint")
	}

	return nil
}
