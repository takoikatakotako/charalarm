package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takoikatakotako/charalarm-worker/entity"
	"github.com/takoikatakotako/charalarm-worker/message"
	"github.com/takoikatakotako/charalarm-worker/repository"
	"github.com/takoikatakotako/charalarm-worker/service"
	"net/http"
)

func Handler(ctx context.Context, event events.SQSEvent) (events.APIGatewayProxyResponse, error) {
	//// Repository
	//snsRepository := &sns.SNSRepository{}
	//sqsRepository := &sqsRepo.SQSRepository{}
	//
	//s := service.CallWorkerService{
	//	SNSRepository: snsRepository,
	//	SQSRepository: sqsRepository,
	//}
	//
	//for _, sqsMessage := range event.Records {
	//	// Decode
	//	req := sqs.IOSVoIPPushAlarmInfoSQSMessage{}
	//	err := json.Unmarshal([]byte(sqsMessage.Body), &req)
	//	if err != nil {
	//		// Decode失敗のためデッドレターキューに送信
	//		err = s.SendMessageToDeadLetter(sqsMessage.Body)
	//		if err == nil {
	//			continue
	//		}
	//		// デッドレターキューに送信にも失敗した場合
	//		return handler.FailureResponse(http.StatusInternalServerError, "Fail")
	//	}
	//
	//	// メッセージを取得して処理する
	//	err = s.PublishPlatformApplication(req)
	//	if err == nil {
	//		continue
	//	}
	//
	//	// デッドレターキューに送信にも失敗した場合
	//	return handler.FailureResponse(http.StatusInternalServerError, "Fail")
	//}

	//awsRepository := repository.AWS{}
	//batchService := service.Batch{
	//	AWS: awsRepository,
	//}
	//
	//// 現在時刻取得
	//t := time.Now().UTC()
	//hour := t.Hour()
	//minute := t.Minute()
	//weekday := t.Weekday()
	//
	//err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	//if err != nil {
	//	fmt.Println(err)
	//} else {
	//	fmt.Println("Finish!!")
	//}
	// Repository
	awsRepository := repository.AWS{}
	//snsRepository := &sns.SNSRepository{}
	//sqsRepository := &sqsRepo.SQSRepository{}

	s := service.CallWorkerService{
		AWS: awsRepository,
	}

	for _, sqsMessage := range event.Records {
		// Decode
		req := entity.IOSVoIPPushAlarmInfoSQSMessage{}
		err := json.Unmarshal([]byte(sqsMessage.Body), &req)
		if err != nil {
			// Decode失敗のためデッドレターキューに送信
			err = s.SendMessageToDeadLetter(sqsMessage.Body)
			if err == nil {
				continue
			}
			// デッドレターキューに送信にも失敗した場合
			return events.APIGatewayProxyResponse{
				Body:       "Error",
				StatusCode: http.StatusInternalServerError,
			}, err
		}

		// メッセージを取得して処理する
		err = s.PublishPlatformApplication(req)
		if err == nil {
			continue
		}

		// デッドレターキューに送信にも失敗した場合
		return events.APIGatewayProxyResponse{
			Body:       "Error",
			StatusCode: http.StatusInternalServerError,
		}, err
	}

	return events.APIGatewayProxyResponse{
		Body:       message.Success,
		StatusCode: http.StatusOK,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
