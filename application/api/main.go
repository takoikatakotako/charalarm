package main

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm-api/handler2"
	"github.com/takoikatakotako/charalarm-api/repository2"
	"github.com/takoikatakotako/charalarm-api/service2"
	"os"
)

func getEnvironment(key string, defaultValue string) string {
	// 環境変数の値を取得
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func main() {
	// environment
	profile := getEnvironment("CHARALARM_AWS_PROFILE", "local")

	// repository
	awsRepository := repository2.AWS{
		Profile: profile,
	}
	environmentRepository := repository2.Environment{
		IsLocal: true,
	}

	// service
	userService := service2.User{
		AWS: awsRepository,
	}
	alarmService := service2.Alarm{
		AWS: awsRepository,
	}
	charaService := service2.Chara{
		AWS:         awsRepository,
		Environment: environmentRepository,
	}
	pushTokenService := service2.PushToken{
		AWS: awsRepository,
	}

	// handler
	healthcheckHandler := handler2.Healthcheck{}
	userHandler := handler2.User{
		Service: userService,
	}
	alarmHandler := handler2.Alarm{
		Service: alarmService,
	}
	charaHandler := handler2.Chara{
		Service: charaService,
	}
	pushTokenHandler := handler2.PushToken{
		Service: pushTokenService,
	}
	newsHandler := handler2.News{}

	e := echo.New()
	e.Use(middleware.Logger())

	// healthcheck
	e.GET("/healthcheck/", healthcheckHandler.HealthcheckGet)

	// user
	e.POST("/user/signup/", userHandler.UserSignupPost)
	e.POST("/user/withdraw/", userHandler.UserWithdrawPost)
	e.GET("/user/info/", userHandler.UserInfoGet)

	// alarm
	e.GET("/alarm/list/", alarmHandler.AlarmListGet)
	e.POST("/alarm/add/", alarmHandler.AlarmAddPost)
	e.POST("/alarm/edit/", alarmHandler.AlarmEditPost)
	e.POST("/alarm/delete/", alarmHandler.AlarmDeletePost)

	// chara
	e.GET("/chara/list/", charaHandler.CharaListGet)
	e.GET("/chara/id/:id/", charaHandler.CharaIDGet)

	// push-token
	e.POST("/push-token/ios/push/add/", pushTokenHandler.PushTokenPushAdd)
	e.POST("/push-token/ios/voip-push/add/", pushTokenHandler.PushTokenVoIPPushAdd)

	// news
	e.GET("/news/list/", newsHandler.NewsListGet)

	e.Logger.Fatal(e.Start(":8080"))
}
