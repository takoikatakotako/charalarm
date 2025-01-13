package main

import (
	"context"
	"encoding/json"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/util/auth"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/entity/request"
	"github.com/takoikatakotako/charalarm-backend/handler"
	"github.com/takoikatakotako/charalarm-backend/service"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	authorizationHeader := event.Headers["Authorization"]
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.AuthenticationFailure)
	}

	body := event.Body
	req := request.AddAlarmRequest{}
	err = json.Unmarshal([]byte(body), &req)
	if err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.InvalidValue)
	}
	requestAlarm := req.Alarm

	dynamodbRepository := &dynamodb.DynamoDBRepository{}
	s := service.AlarmService{DynamoDBRepository: dynamodbRepository}
	if err := s.AddAlarm(userID, authToken, requestAlarm); err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.AlarmAddFailure)
	}

	res := response.MessageResponse{Message: message.AlarmAddSuccess}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
