package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/queue"
	"github.com/takoikatakotako/charalarm/worker/service"
	"net/http"
)

func Handler(ctx context.Context, event events.SQSEvent) (events.APIGatewayProxyResponse, error) {
	// Repository
	awsRepository := infrastructure.AWS{}

	s := service.CallWorkerService{
		AWS: awsRepository,
	}

	for _, sqsMessage := range event.Records {
		// Decode
		req := queue.IOSVoIPPushAlarmInfoSQSMessage{}
		err := json.Unmarshal([]byte(sqsMessage.Body), &req)
		if err != nil {
			fmt.Println("@@@@@@@@@@@")
			fmt.Println("Decode Error")
			fmt.Println("@@@@@@@@@@@")

			// Decode失敗のためデッドレターキューに送信
			err = s.SendMessageToDeadLetter(sqsMessage.Body)
			if err != nil {
				fmt.Println("@@@@@@@@@@@")
				fmt.Println("Failed to Send Dead Letter Error")
				fmt.Println("@@@@@@@@@@@")
				continue
			}
		}

		fmt.Println("@@@@@@@@@@@")
		fmt.Println("Decode Success")
		fmt.Println(req)
		fmt.Println("@@@@@@@@@@@")

		// メッセージを取得して処理する
		err = s.PublishPlatformApplication(req)
		if err != nil {
			fmt.Println("@@@@@@@@@@@")
			fmt.Println("Published Failed")
			fmt.Println(err)
			fmt.Println("@@@@@@@@@@@")
			continue
		}

		//// デッドレターキューに送信にも失敗した場合
		//return events.APIGatewayProxyResponse{
		//	Body:       "Error",
		//	StatusCode: http.StatusInternalServerError,
		//}, err
	}

	return events.APIGatewayProxyResponse{
		Body:       "Success",
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
