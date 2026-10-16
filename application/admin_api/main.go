package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/takoikatakotako/charalarm/admin_api/handler"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/api/service/vertex"
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
	// キャラのリソースは S3 に置き、CloudFront で配る
	// タップのセリフの下書き (Gemini の LLM) とボイス (Gemini TTS)。Vertex AI の設定がなければ作れない
	tapLineService := service.CharaTapLine{
		AWS:            awsRepository,
		Bucket:         os.Getenv("RESOURCE_BUCKET_NAME"),
		DistributionID: os.Getenv("RESOURCE_DISTRIBUTION_ID"),
	}
	gcpEnv := environment.LoadGCPEnvironment()
	if gcpEnv.Project != "" {
		gcpHTTPClient, err := vertex.NewHTTPClient(context.Background(), gcpEnv.CredentialConfig)
		if err != nil {
			log.Fatalf("failed to create vertex client: %v", err)
		}
		ttsEnv := environment.LoadTTSEnvironment()
		tapLineService.LLMClient = llm.NewGeminiClient(gcpEnv.Project, os.Getenv("CHARALARM_LLM_MODEL"), "", gcpHTTPClient)
		tapLineService.TTSClient = tts.NewGeminiClient(gcpEnv.Project, gcpHTTPClient)
		tapLineService.DefaultVoice = tts.Voice{Model: ttsEnv.Model, Name: ttsEnv.Voice}
	}
	tapLineHandler := handler.CharaTapLine{Service: tapLineService}

	charaResourceHandler := handler.CharaResource{
		Service: service.CharaResource{
			AWS:            awsRepository,
			Bucket:         os.Getenv("RESOURCE_BUCKET_NAME"),
			DistributionID: os.Getenv("RESOURCE_DISTRIBUTION_ID"),
		},
	}

	e := echo.New()
	// アクセスログには IP アドレスや User-Agent を出さない (個人情報をサーバに残さないため)
	e.Use(middleware.LoggerWithConfig(middleware.LoggerConfig{
		Format: `{"time":"${time_rfc3339}","method":"${method}","path":"${path}","status":${status},"latency_human":"${latency_human}","error":"${error}"}` + "\n",
	}))
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
	e.POST("/chara", charaHandler.CharaPost)
	e.GET("/chara/:charaID", charaHandler.CharaGet)
	e.PUT("/chara/:charaID", charaHandler.CharaPut)
	e.PUT("/chara/:charaID/assets", charaResourceHandler.AssetsPut)
	e.GET("/tap-line-themes", tapLineHandler.ThemesGet)
	e.PUT("/chara/:charaID/tap-lines", tapLineHandler.LinesPut)
	e.POST("/chara/:charaID/tap-lines/drafts", tapLineHandler.DraftsPost)
	e.POST("/chara/:charaID/tap-lines/voices", tapLineHandler.VoicesPost)
	e.GET("/chara/:charaID/files", charaResourceHandler.FilesGet)
	e.POST("/chara/:charaID/files/upload-url", charaResourceHandler.UploadURLPost)
	e.POST("/chara/:charaID/files/invalidate", charaResourceHandler.InvalidatePost)

	e.Logger.Fatal(e.Start(":8080"))
}
