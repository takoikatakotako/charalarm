package service

import (
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm/api/service/input"
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/api/util/logger"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"runtime"
)

const (
	MaxUsersAlarm = 10
)

type Alarm struct {
	AWS infrastructure.AWS
}

// AddAlarm アラームを追加
func (a *Alarm) AddAlarm(input input.AddAlarm) error {
	// ユーザーを取得
	user, err := a.AWS.GetUser(input.UserID)
	if err != nil {
		return err
	}

	fmt.Println("@@@@@user@@@@@")
	fmt.Println(user.UserID)
	fmt.Println("@@@@@user@@@@@")

	// UserID, AuthToken, Alarm.UserID が一致する
	if user.UserID == input.UserID && user.AuthToken == input.AuthToken && input.Alarm.UserID == input.UserID {
	} else {
		return errors.New(common.ErrorAuthenticationFailure)
	}

	fmt.Println("@@@@@user.UserID@@@@@")
	fmt.Println(user.UserID)
	fmt.Println("@@@@@user.UserID@@@@@")

	// 既に登録されたアラームの件数を取得
	list, err := a.AWS.GetAlarmList(user.UserID)
	if err != nil {
		return err
	}

	fmt.Println("@@@@@list@@@@@")
	fmt.Println(list)
	fmt.Println("@@@@@list@@@@@")

	// 件数が多い場合はエラーを吐く
	if len(list) > MaxUsersAlarm {
		return errors.New("なんか登録してるアラームの件数多くね？")
	}

	// すでに登録されていないか調べる
	isExist, err := a.AWS.IsExistAlarm(input.Alarm.AlarmID)
	if err != nil {
		// すでに登録されているのが贈られてくのは不審
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "すでに登録されたアラーム"
		logger.Warn(msg, fileName, funcName, line)
		return err
	}
	if isExist {
		return errors.New(common.ErrorAlarmAlreadyExists)
	}

	// DatabaseAlarmに変換
	var target string
	if input.Alarm.Type == "IOS_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.PushTokenSNSEndpoint
	} else if input.Alarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint
	} else {
		// 不明なターゲット
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "不明なターゲット"
		logger.Warn(msg, fileName, funcName, line)
		return errors.New(common.ErrorInvalidValue)
	}
	databaseAlarm := convertToDatabaseAlarm(input.Alarm, target)

	// アラームを追加する
	return a.AWS.InsertAlarm(databaseAlarm)
}

// EditAlarm アラームを更新
func (a *Alarm) EditAlarm(input input.EditAlarm) error {
	// ユーザーを取得
	user, err := a.AWS.GetUser(input.UserID)
	if err != nil {
		return err
	}

	// UserID, AuthToken, Alarm.UserID が一致する
	if user.UserID == input.UserID && user.AuthToken == input.AuthToken && input.Alarm.UserID == input.UserID {
	} else {
		return errors.New(common.ErrorAuthenticationFailure)
	}

	// DatabaseAlarmに変換
	var target string
	if input.Alarm.Type == "IOS_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.PushTokenSNSEndpoint
	} else if input.Alarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
		target = user.IOSPlatformInfo.VoIPPushTokenSNSEndpoint
	} else {
		// 不明なターゲット
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := "不明ターゲット"
		logger.Warn(msg, fileName, funcName, line)
		return errors.New(common.ErrorInvalidValue)
	}

	fmt.Println("@@@@@target@@@@@")
	fmt.Println(target)
	fmt.Println("@@@@@target@@@@@")

	databaseAlarm := convertToDatabaseAlarm(input.Alarm, target)

	// アラームを更新する
	return a.AWS.UpdateAlarm(databaseAlarm)
}

// DeleteAlarm アラームを削除
func (a *Alarm) DeleteAlarm(userID string, authToken string, alarmID string) error {
	// ユーザーを取得
	anonymousUser, err := a.AWS.GetUser(userID)
	if err != nil {
		return err
	}

	// UserID, AuthTokenが一致するか確認する
	if anonymousUser.UserID != userID || anonymousUser.AuthToken != authToken {
		return errors.New(common.AuthenticationFailure)
	}

	// アラームを削除する
	return a.AWS.DeleteAlarm(alarmID)
}

// GetAlarms アラームを取得
func (a *Alarm) GetAlarms(userID string, authToken string) (output.GetAlarms, error) {
	// ユーザーを取得
	user, err := a.AWS.GetUser(userID)
	if err != nil {
		fmt.Println("GetUser failer")
		return output.GetAlarms{}, err
	}

	// UserID, AuthTokenが一致するか確認する
	if user.UserID == userID && user.AuthToken == authToken {
		databaseAlarmList, err := a.AWS.GetAlarmList(userID)
		if err != nil {
			fmt.Println("GetAlarms failer")
			return output.GetAlarms{}, err
		}

		// responseAlarmListに変換
		alarms := make([]output.Alarm, 0)
		for i := 0; i < len(databaseAlarmList); i++ {
			databaseAlarm := databaseAlarmList[i]
			responseAlarm := convertToAlarmOutput(databaseAlarm)
			alarms = append(alarms, responseAlarm)
		}

		return output.GetAlarms{
			Alarms: alarms,
		}, nil
	} else {
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		msg := fmt.Sprintf("Authentication Failure, UserID: %s, AuthToken: %s", user.UserID, user.AuthToken)
		logger.Warn(msg, fileName, funcName, line)
		return output.GetAlarms{}, errors.New(common.ErrorAuthenticationFailure)
	}
}
