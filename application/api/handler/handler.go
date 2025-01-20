package handler

import (
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
)

func FailureResponse(statusCode int, message string) (events.APIGatewayProxyResponse, error) {
	res := response.MessageResponse{Message: message}
	jsonBytes, _ := json.Marshal(res)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: statusCode,
	}, nil
}
