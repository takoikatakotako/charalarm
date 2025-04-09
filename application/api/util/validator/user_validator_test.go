package validator

import (
	"github.com/takoikatakotako/charalarm/entity"
	"testing"
)

func TestValidateUser(t *testing.T) {

}

func TestValidateUserIOSPlatformInfo(t *testing.T) {
	iOSPlatformInfo := entity.UserIOSPlatformInfo{
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
