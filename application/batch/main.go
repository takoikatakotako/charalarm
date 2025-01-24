package main

import (
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/takoikatakotako/charalarm-batch/message"
	"github.com/takoikatakotako/charalarm-batch/repository"
	"github.com/takoikatakotako/charalarm-batch/service"
	"net/http"
	"time"
)

func main() {

	awsRepository := repository.AWS{}
	batchService := service.Batch{
		AWS: awsRepository,
	}

	// 現在時刻取得
	t := time.Now().UTC()
	hour := t.Hour()
	minute := t.Minute()
	weekday := t.Weekday()

	err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		res := response.MessageResponse{Message: message.FailedToGetUserInfo}
		jsonBytes, _ := json.Marshal(res)
		return events.APIGatewayProxyResponse{
			Body:       string(jsonBytes),
			StatusCode: http.StatusInternalServerError,
		}, nil
	}

}
