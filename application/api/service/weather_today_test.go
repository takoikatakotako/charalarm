package service

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

func TestWeatherToday(t *testing.T) {
	userID := uuid.New().String()
	authToken := uuid.New().String()

	t.Run("WeatherKit の設定がなければ使えない", func(t *testing.T) {
		s := Weather{}
		_, err := s.Today(context.Background(), userID, authToken, "13")
		assert.ErrorIs(t, err, ErrWeatherNotConfigured)
	})

	t.Run("知らない地域は受け付けず、天気も取らない", func(t *testing.T) {
		fake := &fakeWeather{}
		s := Weather{Forecaster: fake}
		_, err := s.Today(context.Background(), userID, authToken, "99")
		assert.EqualError(t, err, common.ErrorInvalidValue)
		assert.Equal(t, 0, fake.calls)
	})

	t.Run("登録したユーザーに地域の天気を返す", func(t *testing.T) {
		awsRepository := infrastructure.AWS{Profile: "local"}
		assert.NoError(t, (&User{AWS: awsRepository}).Signup(userID, authToken, "iOS"))

		fake := &fakeWeather{}
		s := Weather{AWS: awsRepository, Forecaster: fake}
		got, err := s.Today(context.Background(), userID, authToken, "13")
		assert.NoError(t, err)
		assert.Equal(t, "13", got.Region)
		assert.Equal(t, 17.0, got.TemperatureMax)
		assert.Equal(t, 1, fake.calls)

		_, err = s.Today(context.Background(), userID, uuid.New().String(), "13")
		assert.EqualError(t, err, common.ErrorAuthenticationFailure)
	})
}
