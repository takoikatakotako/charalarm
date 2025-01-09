package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"
)

func Handler(ctx context.Context, name events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	res := response.MessageResponse{Message: message.Healthy}
	jsonBytes, _ := json.Marshal(res)

	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
