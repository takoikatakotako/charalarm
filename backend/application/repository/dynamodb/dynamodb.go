package dynamodb

import (
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"time"
)

type DynamoDBRepository struct {
	IsLocal bool
}

type DynamoDBRepositoryInterface interface {
	QueryByAlarmTime(hour int, minute int, weekday time.Weekday) ([]database.Alarm, error)
	GetChara(charaID string) (database.Chara, error)
	GetRandomChara() (database.Chara, error)
	GetUser(userID string) (database.User, error)
	GetAlarmList(userID string) ([]database.Alarm, error)
	IsExistAlarm(alarmID string) (bool, error)
	InsertUser(user database.User) error
	DeleteAlarm(alarmID string) error
	InsertAlarm(alarm database.Alarm) error
	UpdateAlarm(alarm database.Alarm) error
	IsExistUser(userID string) (bool, error)
	DeleteUser(userID string) error
	GetCharaList() ([]database.Chara, error)
	UpdateUserPremiumPlan(userID string, enablePremiumPlan bool) error
}
