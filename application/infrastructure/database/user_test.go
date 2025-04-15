package database

import (
	"testing"
)

func TestValidateUser(t *testing.T) {

}

func TestValidateUserIOSPlatformInfo(t *testing.T) {
	iOSPlatformInfo := UserIOSPlatformInfo{
		PushToken:                "",
		PushTokenSNSEndpoint:     "",
		VoIPPushToken:            "",
		VoIPPushTokenSNSEndpoint: "",
	}
	err := iOSPlatformInfo.Validate()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}
