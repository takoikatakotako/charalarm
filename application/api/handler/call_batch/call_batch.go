package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/sqs"
	"github.com/takoikatakotako/charalarm-backend/service"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"
	"time"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// 現在時刻取得
	t := time.Now().UTC()
	hour := t.Hour()
	minute := t.Minute()
	weekday := t.Weekday()

	dynamodbRepository := &dynamodb.DynamoDBRepository{}
	sqsRepository := &sqs.SQSRepository{}
	s := service.CallBatchService{
		DynamoDBRepository: dynamodbRepository,
		SQSRepository:      sqsRepository,
	}
	err := s.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		res := response.MessageResponse{Message: message.FailedToGetUserInfo}
		jsonBytes, _ := json.Marshal(res)
		return events.APIGatewayProxyResponse{
			Body:       string(jsonBytes),
			StatusCode: http.StatusInternalServerError,
		}, nil
	}

	res := response.MessageResponse{Message: message.Success}
	jsonBytes, _ := json.Marshal(res)

	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
