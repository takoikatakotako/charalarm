package service2

import (
	"errors"
	"github.com/takoikatakotako/charalarm-api/entity/database"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"github.com/takoikatakotako/charalarm-api/repository2"
	"github.com/takoikatakotako/charalarm-api/util/message"
	"github.com/takoikatakotako/charalarm-api/util/validator"
	"time"
)

type User struct {
	AWS repository2.AWS
}

func (s *User) Signup(userID string, authToken string, platform string, ipAddress string) (response.MessageResponse, error) {
	// バリデーション
	if !validator.IsValidUUID(userID) || !validator.IsValidUUID(authToken) {
		return response.MessageResponse{}, errors.New(message.ErrorInvalidValue)
	}

	// Check User Is Exist
	isExist, err := s.AWS.IsExistUser(userID)
	if err != nil {
		return response.MessageResponse{}, err
	}

	// ユーザーが既に作成されていた場合
	if isExist {
		return response.MessageResponse{Message: message.UserSignupSuccess}, nil
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
	err = s.AWS.InsertUser(user)
	if err != nil {
		return response.MessageResponse{}, err
	}

	return response.MessageResponse{Message: message.UserSignupSuccess}, nil
}
