package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm/batch/service"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"time"
)

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
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
	fmt.Println(event.RequestContext.RequestTime)

	err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		fmt.Println(err)
		return events.APIGatewayProxyResponse{}, nil
	}

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
