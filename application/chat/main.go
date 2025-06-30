package main

import (
	"fmt"
	"log/slog"
	"os"
)

const queueURL = "https://sqs.ap-northeast-1.amazonaws.com/123456789012/my-queue"

func main() {
	// slog のセットアップ
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	slog.Info("ワーカー起動 🚀")
	//
	//// AWS SDK 初期化
	//cfg, err := config.LoadDefaultConfig(context.TODO())
	//if err != nil {
	//	slog.Error("AWS設定読み込み失敗", slog.Any("error", err))
	//	return
	//}
	//client := sqs.NewFromConfig(cfg)
	//
	//for {
	//	msgs, err := receiveMessages(client)
	//	if err != nil {
	//		slog.Warn("メッセージ受信エラー", slog.Any("error", err))
	//		time.Sleep(5 * time.Second)
	//		continue
	//	}
	//
	//	for _, msg := range msgs {
	//		slog.Info("メッセージ受信 📩", slog.String("body", *msg.Body))
	//
	//		response := callLLM(*msg.Body)
	//		saveToDB(response)
	//		sendPushNotification(response)
	//
	//		err := deleteMessage(client, msg.ReceiptHandle)
	//		if err != nil {
	//			slog.Error("メッセージ削除失敗 ❌", slog.Any("error", err))
	//		} else {
	//			slog.Info("メッセージ削除成功 ✅")
	//		}
	//	}
	//
	//	time.Sleep(1 * time.Second)
	//}
	//
	//// メインループ
	//
	//// SQSからメッセージを受け取る
	//
	//// LLMに作ってもらう
	//
	//// DBに保存
	//
	//// プッシュ通知送信
	//
	//// キューを削除

	fmt.Println("hello")
}

//
//// SQSからメッセージを受信
//func receiveMessages(client *sqs.Client) ([]sqs.Message, error) {
//	out, err := client.ReceiveMessage(context.TODO(), &sqs.ReceiveMessageInput{
//		QueueUrl:            &queueURL,
//		MaxNumberOfMessages: 1,
//		WaitTimeSeconds:     5,
//	})
//	if err != nil {
//		return nil, err
//	}
//	return out.Messages, nil
//}
//
//// LLM処理（仮）
//func callLLM(prompt string) string {
//	slog.Info("LLM呼び出し 🧠", slog.String("prompt", prompt))
//	return "LLMの出力: " + prompt
//}
//
//// DBに保存（仮）
//func saveToDB(data string) {
//	slog.Info("DBに保存 💾", slog.String("data", data))
//}
//
//// プッシュ通知送信（仮）
//func sendPushNotification(msg string) {
//	slog.Info("プッシュ通知送信 📲", slog.String("message", msg))
//}
//
//// メッセージを削除
//func deleteMessage(client *sqs.Client, receiptHandle *string) error {
//	_, err := client.DeleteMessage(context.TODO(), &sqs.DeleteMessageInput{
//		QueueUrl:      &queueURL,
//		ReceiptHandle: receiptHandle,
//	})
//	return err
}