package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm/batch/service"
	"github.com/takoikatakotako/charalarm/repository"
	"os"
	"time"
)

func getEnvironment(key string, defaultValue string) string {
	// 環境変数の値を取得
	val, exists := os.LookupEnv(key)
	if !exists {
		return defaultValue
	}
	return val
}

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// environment
	profile := getEnvironment("CHARALARM_AWS_PROFILE", "local")
	resourceBaseURL := getEnvironment("RESOURCE_BASE_URL", "http://localhost:4566")

	// Repository
	awsRepository := repository.AWS{
		Profile: profile,
	}

	environmentRepository := repository.Environment{
		ResourceBaseURL: resourceBaseURL,
	}

	// Service
	batchService := service.Batch{
		AWS:         awsRepository,
		Environment: environmentRepository,
	}

	// 現在時刻取得
	t := time.Now().UTC()
	hour := t.Hour()
	minute := t.Minute()
	weekday := t.Weekday()

	fmt.Println(hour, minute, weekday)
	fmt.Println(event.RequestContext.RequestTime)

	err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		fmt.Println(err)
		return events.APIGatewayProxyResponse{}, nil
	}

	//
	//message := event.Body
	//fmt.Println(message)
	//
	//// Decode
	//var req Request
	//err := json.Unmarshal([]byte(message), &req)
	//if err != nil {
	//	return events.APIGatewayProxyResponse{}, err
	//}
	//
	//// Create Response
	//res := Response{
	//	Message: "Request Message is " + req.Message,
	//}

	// Encode
	//jsonData, err := json.Marshal(res)
	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string("Success!!"),
	}
	return response, nil
}

func main() {
	lambda.Start(handler)
}
