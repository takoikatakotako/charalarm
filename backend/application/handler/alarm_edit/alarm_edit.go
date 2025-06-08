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
		return handler.FailureResponse(http.StatusForbidden, message.AuthenticationFailure)
	}

	body := event.Body
	req := request.AddAlarmRequest{}

	if err := json.Unmarshal([]byte(body), &req); err != nil {
		return handler.FailureResponse(http.StatusForbidden, message.InvalidValue)
	}

	alarm := req.Alarm

	s := service.AlarmService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}

	if err := s.EditAlarm(userID, authToken, alarm); err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.AlarmEditFailure)
	}

	res := response.MessageResponse{Message: message.AlarmEditSuccess}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
