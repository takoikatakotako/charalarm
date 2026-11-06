package service

import (
	"context"
	"errors"

	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/api/service/weather"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// ErrWeatherNotConfigured は WeatherKit の設定がない環境で天気を求められたとき。
var ErrWeatherNotConfigured = errors.New("weather is not configured")

// Weather はアプリのトップに出す今日の天気を返す。
// 地域はユーザーが端末で選んだもので、サーバには保存せず、ログにも出さない。
type Weather struct {
	AWS infrastructure.AWS
	// Forecaster は天気予報。nil なら天気を使わない (WeatherKit の設定がないとき)。
	// 地域ごとに 1 時間キャッシュするので、呼ばれるたびに WeatherKit を呼ぶことはない。
	Forecaster WeatherForecaster
}

// Today はユーザーを認証したうえで、地域の今日の天気を返す。
func (s *Weather) Today(ctx context.Context, userID string, authToken string, regionCode string) (output.Weather, error) {
	if s.Forecaster == nil {
		return output.Weather{}, ErrWeatherNotConfigured
	}
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return output.Weather{}, errors.New(common.ErrorInvalidValue)
	}
	region, ok := weather.FindRegion(regionCode)
	if !ok {
		return output.Weather{}, errors.New(common.ErrorInvalidValue)
	}

	// 実在するユーザーだけに返す (WeatherKit の無料枠を守るため)
	user, err := s.AWS.GetUser(userID)
	if err != nil {
		return output.Weather{}, err
	}
	if user.UserID != userID || user.AuthToken != authToken {
		return output.Weather{}, errors.New(common.ErrorAuthenticationFailure)
	}

	forecast, err := s.Forecaster.Today(ctx, region)
	if err != nil {
		return output.Weather{}, err
	}
	return output.Weather{
		Region:              region.Code,
		ConditionCode:       forecast.ConditionCode,
		TemperatureMax:      forecast.TemperatureMax,
		TemperatureMin:      forecast.TemperatureMin,
		PrecipitationChance: forecast.PrecipitationChance,
	}, nil
}
