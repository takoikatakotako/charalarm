package main

import (
	"context"
	"encoding/json"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/entity/request"
	"github.com/takoikatakotako/charalarm-backend/handler"
	"github.com/takoikatakotako/charalarm-backend/service"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	body := event.Body

	// Decode Body
	req := request.UserSignUp{}
	if err := json.Unmarshal([]byte(body), &req); err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.InvalidRequestParameter)
	}

	// Get Parameters
	userID := req.UserID
	authToken := req.AuthToken
	platform := req.Platform
	ipAddress := event.RequestContext.Identity.SourceIP

	// Signup
	s := service.UserService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}
	if err := s.Signup(userID, authToken, platform, ipAddress); err != nil {
		return handler.FailureResponse(http.StatusBadRequest, message.UserSignupFailure)
	}

	// Success
	res := response.MessageResponse{Message: message.UserSignupSuccess}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
