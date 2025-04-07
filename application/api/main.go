package main

import (
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm/api/handler"
	"github.com/takoikatakotako/charalarm/api/repository"
	"github.com/takoikatakotako/charalarm/api/service"
	"os"
)

func getEnvironment(key string, defaultValue string) string {
	// 環境変数の値を取得
	val, exists := os.LookupEnv(key)
	if !exists {
		return defaultValue
	}
	return val
}

func main() {
	// environment
	profile := getEnvironment("CHARALARM_AWS_PROFILE", "local")
	resourceBaseURL := getEnvironment("RESOURCE_BASE_URL", "http://localhost:4566")
	fmt.Printf("profile is %s\n", profile)

	// repository
	awsRepository := repository.AWS{
		Profile: profile,
	}
	environmentRepository := repository.Environment{
		ResourceBaseURL: resourceBaseURL,
	}

	// service
	userService := service.User{
		AWS: awsRepository,
	}
	alarmService := service.Alarm{
		AWS: awsRepository,
	}
	charaService := service.Chara{
		AWS:         awsRepository,
		Environment: environmentRepository,
	}
	pushTokenService := service.PushToken{
		AWS: awsRepository,
	}

	// handler
	healthcheckHandler := handler.Healthcheck{}
	maintenanceHandler := handler.Maintenance{}
	requireHandler := handler.Require{}
	userHandler := handler.User{
		Service: userService,
	}
	alarmHandler := handler.Alarm{
		Service: alarmService,
	}
	charaHandler := handler.Chara{
		Service: charaService,
	}
	pushTokenHandler := handler.PushToken{
		Service: pushTokenService,
	}
	newsHandler := handler.News{}

	e := echo.New()
	e.Use(middleware.Logger())

	// healthcheck
	e.GET("/healthcheck", healthcheckHandler.HealthcheckGet)

	// maintenance
	e.GET("/maintenance", maintenanceHandler.MaintenanceGet)

	// require
	e.GET("/require", requireHandler.RequireGet)

	// user
	e.GET("/user/info", userHandler.UserInfoGet)
	e.POST("/user/signup", userHandler.UserSignupPost)
	e.POST("/user/update-premium", userHandler.UserUpdatePremiumPost)
	e.POST("/user/withdraw", userHandler.UserWithdrawPost)

	// alarm
	e.GET("/alarm/list", alarmHandler.AlarmListGet)
	e.POST("/alarm/add", alarmHandler.AlarmAddPost)
	e.POST("/alarm/edit", alarmHandler.AlarmEditPost)
	e.POST("/alarm/delete", alarmHandler.AlarmDeletePost)

	// chara
	e.GET("/chara/list", charaHandler.CharaListGet)
	e.GET("/chara/id/:charaID", charaHandler.CharaIDGet)

	// push-token
	e.POST("/push-token/ios/push/add", pushTokenHandler.PushTokenPushAdd)
	e.POST("/push-token/ios/voip-push/add", pushTokenHandler.PushTokenVoIPPushAdd)

	// news
	e.GET("/news/list", newsHandler.NewsListGet)

	e.Logger.Fatal(e.Start(":8080"))
}
