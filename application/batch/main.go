package main

import (
	"fmt"
	"github.com/takoikatakotako/charalarm-batch/repository"
	"github.com/takoikatakotako/charalarm-batch/service"
	"time"
)

func main() {

	awsRepository := repository.AWS{}
	batchService := service.Batch{
		AWS: awsRepository,
	}

	// 現在時刻取得
	t := time.Now().UTC()
	hour := t.Hour()
	minute := t.Minute()
	weekday := t.Weekday()

	err := batchService.QueryDynamoDBAndSendMessage(hour, minute, weekday)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println("Finish!!")
	}
}
