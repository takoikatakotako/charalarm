package main

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm/admin_api/handler"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

func main() {
	env := environment.Environment{}
	env.SetCharalarmAWSProfile("local")

	awsRepository := infrastructure.AWS{
		Profile: env.Profile,
	}

	userService := service.User{
		AWS: awsRepository,
	}
	alarmService := service.Alarm{
		AWS: awsRepository,
	}
	newsService := service.News{
		AWS: awsRepository,
	}

	healthcheckHandler := handler.Healthcheck{}
	userHandler := handler.User{
		Service: userService,
	}
	alarmHandler := handler.Alarm{
		Service: alarmService,
	}
	newsHandler := handler.News{
		Service: newsService,
	}

	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.GET("/healthcheck", healthcheckHandler.HealthcheckGet)

	e.GET("/users", userHandler.UsersGet)
	e.GET("/users/:userID", userHandler.UserGet)
	e.GET("/users/:userID/alarms", alarmHandler.UserAlarmsGet)

	e.GET("/news", newsHandler.NewsListGet)
	e.POST("/news", newsHandler.NewsPost)
	e.DELETE("/news/:newsID", newsHandler.NewsDelete)

	e.Logger.Fatal(e.Start(":8080"))
}
