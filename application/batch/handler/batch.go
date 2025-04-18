package main

//
//import (
//	"github.com/labstack/echo/v4"
//	"github.com/takoikatakotako/charalarm-backend/entity/response"
//	"github.com/takoikatakotako/charalarm-backend/service"
//	"net/http"
//)
//
//type Batch struct {
//	Service service.Batch
//}
//
//func (b *Batch) AlarmListGet(c echo.Context) error {
//	authorizationHeader := c.Request().Header.Get("Authorization")
//	userID, authToken, err := auth.Basic(authorizationHeader)
//	if err != nil {
//		res := response.Message{Message: "Error!"}
//		return c.JSON(http.StatusInternalServerError, res)
//	}
//
//	res, err := a.Service.GetAlarms(userID, authToken)
//	if err != nil {
//		res := response.Message{Message: "Error!"}
//		return c.JSON(http.StatusInternalServerError, res)
//	}
//
//	return c.JSON(http.StatusOK, res)
//}
//
////
////func Handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
////	// 現在時刻取得
////	t := time.Now().UTC()
////	hour := t.Hour()
////	minute := t.Minute()
////	weekday := t.Weekday()
////
////	dynamodbRepository := &dynamodb.DynamoDBRepository{}
////	sqsRepository := &sqs.SQSRepository{}
////	s := service.CallBatchService{
////		DynamoDBRepository: dynamodbRepository,
////		SQSRepository:      sqsRepository,
////	}
////	err := s.QueryDynamoDBAndSendMessage(hour, minute, weekday)
////	if err != nil {
////		res := response.MessageResponse{Message: message.FailedToGetUserInfo}
////		jsonBytes, _ := json.Marshal(res)
////		return events.APIGatewayProxyResponse{
////			Body:       string(jsonBytes),
////			StatusCode: http.StatusInternalServerError,
////		}, nil
////	}
////
////	res := response.MessageResponse{Message: message.Success}
////	jsonBytes, _ := json.Marshal(res)
////
////	return events.APIGatewayProxyResponse{
////		Body:       string(jsonBytes),
////		StatusCode: http.StatusOK,
////	}, nil
////}
////
////func main() {
////	lambda.Start(Handler)
////}
