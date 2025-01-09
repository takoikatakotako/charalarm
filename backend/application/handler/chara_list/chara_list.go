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

	// CharaList
	s := service.CharaService{DynamoDBRepository: &dynamodb.DynamoDBRepository{}}
	charaList, err := s.GetCharaList()
	if err != nil {
		fmt.Println(err)
		return handler.FailureResponse(http.StatusInternalServerError, message.CharaListFailure)
	}

	jsonBytes, _ := json.Marshal(charaList)
	return events.APIGatewayProxyResponse{
		Body:       string(jsonBytes),
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
