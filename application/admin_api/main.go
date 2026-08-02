package main

import (
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm/admin_api/handler"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

// originVerifyMiddleware は CloudFront が注入する共有秘密ヘッダを検証する。
// admin_api の Function URL は auth=NONE(公開)のため、生URLの直叩きを防ぐ。
// ADMIN_ORIGIN_SECRET が未設定(ローカル開発等)の場合は検証をスキップする。
func originVerifyMiddleware(secret string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// ヘルスチェックは素通し
			if c.Path() == "/healthcheck" {
				return next(c)
			}
			// 秘密が未設定なら検証しない(ローカル開発向け)
			if secret == "" {
				return next(c)
			}
			if c.Request().Header.Get("X-Origin-Verify") != secret {
				return c.NoContent(http.StatusForbidden)
			}
			return next(c)
		}
	}
}

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
	charaService := service.Chara{
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
	charaHandler := handler.Chara{
		Service: charaService,
	}

	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(originVerifyMiddleware(os.Getenv("ADMIN_ORIGIN_SECRET")))

	e.GET("/healthcheck", healthcheckHandler.HealthcheckGet)

	e.GET("/users", userHandler.UsersGet)
	e.GET("/users/:userID", userHandler.UserGet)
	e.GET("/users/:userID/alarms", alarmHandler.UserAlarmsGet)

	e.GET("/news", newsHandler.NewsListGet)
	e.POST("/news", newsHandler.NewsPost)
	e.DELETE("/news/:newsID", newsHandler.NewsDelete)

	e.GET("/chara", charaHandler.CharaListGet)
	e.GET("/chara/:charaID", charaHandler.CharaGet)

	e.Logger.Fatal(e.Start(":8080"))
}
