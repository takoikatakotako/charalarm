package service

import (
	"github.com/takoikatakotako/charalarm-worker/entity"
	"github.com/takoikatakotako/charalarm-worker/repository"
)

//import (
//	"github.com/takoikatakotako/charalarm-worker/entity/sns"
//	"github.com/takoikatakotako/charalarm-worker/entity/sqs"
//	sns2 "github.com/takoikatakotako/charalarm-worker/repository/sns"
//	sqs2 "github.com/takoikatakotako/charalarm-worker/repository/sqs"
//	// "github.com/takoikatakotako/charalarm-backend/validator"
//)

type CallWorkerService struct {
	//SNSRepository sns2.SNSRepositoryInterface
	//SQSRepository sqs2.SQSRepositoryInterface
	AWS repository.AWS
}

// PublishPlatformApplication VoIPのプッシュ通知をする

func (s *CallWorkerService) PublishPlatformApplication(alarmInfo entity.IOSVoIPPushAlarmInfoSQSMessage) error {
	// エンドポイントが有効か確認
	err := s.AWS.CheckPlatformEndpointEnabled(alarmInfo.SNSEndpointArn)
	if err != nil {
		return err
	}

	// 送信用の Message に変換
	iOSVoIPPushSNSMessage := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	iOSVoIPPushSNSMessage.CharaID = alarmInfo.CharaID
	iOSVoIPPushSNSMessage.CharaName = alarmInfo.CharaName
	iOSVoIPPushSNSMessage.VoiceFileURL = alarmInfo.VoiceFileURL

	// メッセージを送信
	return s.PublishPlatformApplication(iOSVoIPPushSNSMessage)
}

// SendMessageToDeadLetter エラーのあるメッセージをデッドレターに送信
func (s *CallWorkerService) SendMessageToDeadLetter(messageBody string) error {
	// キューに送信
	return s.AWS.SendMessageToVoIPPushDeadLetterQueue(messageBody)
}
