package service

import (
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type User struct {
	AWS infrastructure.AWS
}

func (u *User) ScanUsers(limit int, cursor string) (output.ScanUsersResult, error) {
	users, nextCursor, err := u.AWS.ScanUsers(limit, cursor)
	if err != nil {
		return output.ScanUsersResult{}, err
	}

	out := make([]output.User, 0, len(users))
	for _, user := range users {
		out = append(out, toUserOutput(user))
	}
	return output.ScanUsersResult{
		Users:      out,
		NextCursor: nextCursor,
	}, nil
}

func (u *User) GetUser(userID string) (output.User, error) {
	user, err := u.AWS.GetUser(userID)
	if err != nil {
		return output.User{}, err
	}
	return toUserOutput(user), nil
}

func toUserOutput(u database.User) output.User {
	return output.User{
		UserID:              u.UserID,
		Platform:            u.Platform,
		PremiumPlan:         u.PremiumPlan,
		CreatedAt:           u.CreatedAt,
		UpdatedAt:           u.UpdatedAt,
		RegisteredIPAddress: u.RegisteredIPAddress,
		IOSPlatformInfo: output.IOSPlatformInfo{
			PushToken:                u.IOSPlatformInfo.PushToken,
			PushTokenSNSEndpoint:     u.IOSPlatformInfo.PushTokenSNSEndpoint,
			VoIPPushToken:            u.IOSPlatformInfo.VoIPPushToken,
			VoIPPushTokenSNSEndpoint: u.IOSPlatformInfo.VoIPPushTokenSNSEndpoint,
		},
	}
}
