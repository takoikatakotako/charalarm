package service

import (
	entity2 "github.com/takoikatakotako/charalarm/entity"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

type CallWorkerService struct {
	AWS infrastructure.AWS
}

func (s *CallWorkerService) PublishPlatformApplication(alarmInfo entity2.IOSVoIPPushAlarmInfoSQSMessage) error {
	// エンドポイントが有効か確認
	err := s.AWS.CheckPlatformEndpointEnabled(alarmInfo.SNSEndpointArn)
	if err != nil {
		return err
	}

	// 送信用の Message に変換
	iOSVoIPPushSNSMessage := entity2.IOSVoIPPushSNSMessage{}
	iOSVoIPPushSNSMessage.CharaID = alarmInfo.CharaID
	iOSVoIPPushSNSMessage.CharaName = alarmInfo.CharaName
	iOSVoIPPushSNSMessage.VoiceFileURL = alarmInfo.VoiceFileURL

	// メッセージを送信
	return s.AWS.PublishPlatformApplication(alarmInfo.SNSEndpointArn, iOSVoIPPushSNSMessage)
}

// SendMessageToDeadLetter エラーのあるメッセージをデッドレターに送信
func (s *CallWorkerService) SendMessageToDeadLetter(messageBody string) error {
	// キューに送信
	return s.AWS.SendMessageToVoIPPushDeadLetterQueue(messageBody)
}
