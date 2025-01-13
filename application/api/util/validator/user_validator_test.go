package validator

import (
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"testing"
)

func TestValidateUser(t *testing.T) {

}

func TestValidateUserIOSPlatformInfo(t *testing.T) {
	iOSPlatformInfo := database.UserIOSPlatformInfo{
		PushToken:                "",
		PushTokenSNSEndpoint:     "",
		VoIPPushToken:            "",
		VoIPPushTokenSNSEndpoint: "",
	}
	err := ValidateUserIOSPlatformInfo(iOSPlatformInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}
