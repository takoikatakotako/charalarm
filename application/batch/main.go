package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/api/service/vertex"
	"github.com/takoikatakotako/charalarm/batch/service"
	"github.com/takoikatakotako/charalarm/batch/trendnews"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

// jobTrendNews は話題のニュースを作り直す (EventBridge の別の規則から 1 日に数回呼ぶ)。
// job が無ければ、毎分のアラームの処理をする。
const jobTrendNews = "trendNews"

// batchEvent は EventBridge から渡る入力。毎分の規則は入力を指定しないので Job は空になる。
type batchEvent struct {
	Job string `json:"job"`
}

func handler(ctx context.Context, raw json.RawMessage) (events.APIGatewayProxyResponse, error) {
	var event batchEvent
	_ = json.Unmarshal(raw, &event)

	if event.Job == jobTrendNews {
		if err := runTrendNews(ctx); err != nil {
			slog.Error("trend news failed", slog.String("error", err.Error()))
			return events.APIGatewayProxyResponse{}, err
		}
		return events.APIGatewayProxyResponse{StatusCode: 200, Body: "Success!!"}, nil
	}
	return runAlarm()
}

func runAlarm() (events.APIGatewayProxyResponse, error) {
	// environment
	env := environment.Environment{}
	env.SetCharalarmAWSProfile("")
	env.SetResourceBaseURL("")

	// Repository
	awsRepository := infrastructure.AWS{
		Profile: env.Profile,
	}

	// Service
	batchService := service.Batch{
		AWS:         awsRepository,
		Environment: env,
	}

	// 現在時刻取得
	t := time.Now().UTC()
	hour := t.Hour()
	minute := t.Minute()
	weekday := t.Weekday()

	fmt.Println(hour, minute, weekday)

	err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		fmt.Println(err)
		return events.APIGatewayProxyResponse{}, nil
	}

	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string("Success!!"),
	}
	return response, nil
}

// runTrendNews は X のニュースを取り、Gemini で子ども（9+）が朝に聞いてよいものを選び、resource のバケットに置く。
func runTrendNews(ctx context.Context) error {
	// X の Bearer Token は "ssm://" で Parameter Store から読む
	if err := environment.ResolveSSMEnv(ctx); err != nil {
		return err
	}
	env := environment.LoadTrendNewsEnvironment()
	if env.XBearerToken == "" || env.ResourceBucketName == "" || env.GCPProject == "" {
		return errors.New("trend news: CHARALARM_X_BEARER_TOKEN, CHARALARM_RESOURCE_BUCKET_NAME and CHARALARM_GCP_PROJECT are required")
	}

	httpClient, err := vertex.NewHTTPClient(ctx, env.GCPCredentialConfig)
	if err != nil {
		return err
	}
	job := trendnews.Job{
		Searcher:  trendnews.NewXClient(env.XBearerToken),
		LLM:       llm.NewGeminiClient(env.GCPProject, env.LLMModel, "", httpClient),
		Publisher: trendnews.S3Publisher{AWS: infrastructure.AWS{Profile: os.Getenv("CHARALARM_AWS_PROFILE")}, Bucket: env.ResourceBucketName},
	}
	return job.Run(ctx)
}

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	lambda.Start(handler)
}
