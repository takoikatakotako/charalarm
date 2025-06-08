package service

import (
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm-backend/entity/request"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/util/converter"
	"github.com/takoikatakotako/charalarm-backend/util/logger"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"runtime"
)

const (
	MaxUsersAlarm = 10
)

type AlarmService struct {
	DynamoDBRepository dynamodb.DynamoDBRepositoryInterface
}

// AddAlarm アラームを追加
func (s *AlarmService) AddAlarm(userID string, authToken string, requestAlarm request.Alarm) error {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthToken, Alarm.UserID が一致する
	if user.UserID == userID && user.AuthToken == authToken && requestAlarm.UserID == userID {
	} else {
		return errors.New(message.ErrorAuthenticationFailure)
	}

	// 既に登録されたアラームの件数を取得
	list, err := s.DynamoDBRepository.GetAlarmList(userID)
	if err != nil {
		return err
	}

	// 件数が多い場合はエラーを吐く
	if len(list) > MaxUsersAlarm {
		return errors.New("なんか登録してるアラームの件数多くね？")
	}

	// すでに登録されていないか調べる
	isExist, err := s.DynamoDBRepository.IsExistAlarm(requestAlarm.AlarmID)
	if err != nil {
		// すでに登録されているのが贈られてくのは不審
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "すでに登録されたアラーム"
		logger.Warn(msg, fileName, funcName, line)
		return err
	}
	if isExist {
		return errors.New(message.ErrorAlarmAlreadyExists)
	}

	// DatabaseAlarmに変換
	var target string
	if requestAlarm.Type == "IOS_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.PushTokenSNSEndpoint
	} else if requestAlarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint
	} else {
		// 不明なターゲット
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "不明なターゲット"
		logger.Warn(msg, fileName, funcName, line)
		return errors.New(message.ErrorInvalidValue)
	}
	databaseAlarm := converter.RequestAlarmToDatabaseAlarm(requestAlarm, target)

	// アラームを追加する
	return s.DynamoDBRepository.InsertAlarm(databaseAlarm)
}

// EditAlarm アラームを更新
func (s *AlarmService) EditAlarm(userID string, authToken string, requestAlarm request.Alarm) error {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthToken, Alarm.UserID が一致する
	if user.UserID == userID && user.AuthToken == authToken && requestAlarm.UserID == userID {
	} else {
		return errors.New(message.ErrorAuthenticationFailure)
	}

	// DatabaseAlarmに変換
	var target string
	if requestAlarm.Type == "IOS_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.PushTokenSNSEndpoint
	} else if requestAlarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint
	} else {
		// 不明なターゲット
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "不明ターゲット"
		logger.Warn(msg, fileName, funcName, line)
		return errors.New(message.ErrorInvalidValue)
	}
	databaseAlarm := converter.RequestAlarmToDatabaseAlarm(requestAlarm, target)

	// アラームを更新する
	return s.DynamoDBRepository.UpdateAlarm(databaseAlarm)
}

// DeleteAlarm アラームを削除
func (s *AlarmService) DeleteAlarm(userID string, authToken string, alarmID string) error {
	// ユーザーを取得
	anonymousUser, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenが一致するか確認する
	if anonymousUser.UserID != userID || anonymousUser.AuthToken != authToken {
		return errors.New(message.AuthenticationFailure)
	}

	// アラームを削除する
	return s.DynamoDBRepository.DeleteAlarm(alarmID)
}

// GetAlarmList アラームを取得
func (s *AlarmService) GetAlarmList(userID string, authToken string) ([]response.Alarm, error) {
	// ユーザーを取得
	user, err := s.DynamoDBRepository.GetUser(userID)
	if err != nil {
		return []response.Alarm{}, err
	}

	// UserID, AuthTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		databaseAlarmList, err := s.DynamoDBRepository.GetAlarmList(userID)
		if err != nil {
			return []response.Alarm{}, err
		}

		// responseAlarmListに変換
		responseAlarmList := make([]response.Alarm, 0)
		for i := 0; i < len(databaseAlarmList); i++ {
			databaseAlarm := databaseAlarmList[i]
			responseAlarm := converter.DatabaseAlarmToResponseAlarm(databaseAlarm)
			responseAlarmList = append(responseAlarmList, responseAlarm)
		}
		return responseAlarmList, nil
	} else {
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := fmt.Sprintf("Authentication Failure, UserID: %s, AuthToken: %s", user.UserID, user.AuthToken)
		logger.Warn(msg, fileName, funcName, line)
		return []response.Alarm{}, errors.New(message.ErrorAuthenticationFailure)
	}
}
