package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/handler"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/service"
	"github.com/takoikatakotako/charalarm-backend/util/auth"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	authorizationHeader := event.Headers["Authorization"]
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.AuthenticationFailure)
	}

	// info
	s := service.UserService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}
	userInfo, err := s.GetUser(userID, authToken)
	if err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.FailedToGetUserInfo)
	}

	// Success
	jsonBytes, _ := json.Marshal(userInfo)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
