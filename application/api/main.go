package main

import (
	"context"
	"log"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm/api/handler"
	"github.com/takoikatakotako/charalarm/api/service"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

func main() {
	// "ssm:///path" 形式の環境変数を Parameter Store の値に解決する
	// (OPENAI_API_KEY 等の秘密値を Lambda 環境変数/state に平文で残さないため)
	if err := environment.ResolveSSMEnv(context.Background()); err != nil {
		log.Fatalf("failed to resolve SSM environment variables: %v", err)
	}

	// environment
	env := environment.Environment{}
	env.SetCharalarmAWSProfile("local")
	env.SetResourceBaseURL("http://localhost:4566")
	env.SetLLMProvider("openai")
	env.SetLLMModel("gpt-4o-mini")
	env.SetOpenAIAPIKey("")

	// infrastructure
	awsRepository := infrastructure.AWS{
		Profile: env.Profile,
	}

	// service
	userService := service.User{
		AWS: awsRepository,
	}
	alarmService := service.Alarm{
		AWS: awsRepository,
	}
	charaService := service.Chara{
		AWS:             awsRepository,
		ResourceBaseURL: env.ResourceBaseURL,
	}
	pushTokenService := service.PushToken{
		AWS: awsRepository,
	}
	newsService := service.News{
		AWS: awsRepository,
	}
	chatService := service.Chat{
		AWS:       awsRepository,
		LLMClient: llm.NewClient(env.LLMProvider, env.OpenAIAPIKey, env.LLMModel),
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
	newsHandler := handler.News{
		Service: newsService,
	}
	chatHandler := handler.Chat{
		Service: chatService,
	}

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

	// chat (ずんだもんとの会話)
	e.POST("/chat", chatHandler.ChatPost)

	e.Logger.Fatal(e.Start(":8080"))
}
