package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-backend/handler"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/service"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"net/http"
)

func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Get Path Parameters
	charaID := event.PathParameters["id"]

	// Get Chara
	s := service.CharaService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}
	chara, err := s.GetChara(charaID)
	if err != nil {
		fmt.Println(err)
		return handler.FailureResponse(http.StatusInternalServerError, message.CharaListFailure)
	}

	jsonBytes, _ := json.Marshal(chara)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
