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
	// Decode Header
	authorizationHeader := event.Headers["Authorization"]
	userID, authToken, err := auth.Basic(authorizationHeader)
	if err != nil {
		return handler.FailureResponse(http.StatusInternalServerError, message.AuthenticationFailure)
	}

	// Decode Body
	body := event.Body
	req := request.UserUpdatePremiumPlan{}
	if err := json.Unmarshal([]byte(body), &req); err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.InvalidRequestParameter)
	}

	// Get Parameters
	enablePremiumPlan := req.EnablePremiumPlan

	// Update Premium Plan
	s := service.UserService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}
	if err := s.UpdatePremiumPlan(userID, authToken, enablePremiumPlan); err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.UserSignupFailure)
	}

	// Success
	res := response.MessageResponse{Message: message.UserUpdateSuccess}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
