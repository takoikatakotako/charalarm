package main

import (
	"context"
	"encoding/json"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/sns"
	"github.com/takoikatakotako/charalarm-backend/util/auth"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/handler"
	"github.com/takoikatakotako/charalarm-backend/service"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	authorizationHeader := event.Headers["Authorization"]
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.ErrorInvalidValue)
	}

	// Withdraw
	s := service.UserService{
		DynamoDBRepository: &dynamodb.DynamoDBRepository{},
		SNSRepository:      &sns.SNSRepository{},
	}
	err = s.Withdraw(userID, authToken)
	if err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.FailedToWithdraw)
	}

	// Success
	res := response.MessageResponse{Message: message.WithdrawSuccess}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
