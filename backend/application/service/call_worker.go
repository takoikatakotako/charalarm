package service

import (
	"github.com/takoikatakotako/charalarm-backend/entity/sns"
	"github.com/takoikatakotako/charalarm-backend/entity/sqs"
	sns2 "github.com/takoikatakotako/charalarm-backend/repository/sns"
	sqs2 "github.com/takoikatakotako/charalarm-backend/repository/sqs"
	// "github.com/takoikatakotako/charalarm-backend/validator"
)

type CallWorkerService struct {
	SNSRepository sns2.SNSRepositoryInterface
	SQSRepository sqs2.SQSRepositoryInterface
}

// PublishPlatformApplication VoIPのプッシュ通知をする
func (service *CallWorkerService) PublishPlatformApplication(alarmInfo sqs.IOSVoIPPushAlarmInfoSQSMessage) error {
	// エンドポイントが有効か確認
	err := service.SNSRepository.CheckPlatformEndpointEnabled(alarmInfo.SNSEndpointArn)
	if err != nil {
		return err
	}

	// 送信用の Message に変換
	iOSVoIPPushSNSMessage := sns.IOSVoIPPushSNSMessage{}
	iOSVoIPPushSNSMessage.CharaID = alarmInfo.CharaID
	iOSVoIPPushSNSMessage.CharaName = alarmInfo.CharaName
	iOSVoIPPushSNSMessage.VoiceFileURL = alarmInfo.VoiceFileURL

	// メッセージを送信
	return service.SNSRepository.PublishPlatformApplication(alarmInfo.SNSEndpointArn, iOSVoIPPushSNSMessage)
}

// SendMessageToDeadLetter エラーのあるメッセージをデッドレターに送信
func (service *CallWorkerService) SendMessageToDeadLetter(messageBody string) error {
	// キューに送信
	return service.SQSRepository.SendMessageToVoIPPushDeadLetterQueue(messageBody)
}
