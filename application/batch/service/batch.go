package service

import (
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm/batch/logger"
	entity2 "github.com/takoikatakotako/charalarm/entity"
	"github.com/takoikatakotako/charalarm/repository"
	"math/rand"
	"runtime"
	"time"
)

type Batch struct {
	AWS                            repository.AWS
	Environment                    repository.Environment
	randomCharaNameAndVoiceFileURL map[string]CharaNameAndVoiceFilePath
}

type CharaNameAndVoiceFilePath struct {
	CharaID       string
	CharaName     string
	VoiceFilePath string
}

func (b *Batch) QueryDynamoDBAndSendMessage(hour int, minute int, weekday time.Weekday) error {
	// クエリでアラームを取得
	alarmList, err := b.AWS.QueryByAlarmTime(hour, minute, weekday)
	if err != nil {
		return err
	}

	// BaseURLを取得
	resourceBaseURL := b.Environment.ResourceBaseURL
	if err != nil {
		return err
	}

	// 何回もDynamoDBにアクセスすると結構大変だからメモ化する

	// ランダム再生用のキャラクターのボイスを取得
	randomChara, err := b.AWS.GetRandomChara()
	if err != nil {
		return err
	}
	randomCharaCallVoicesCount := len(randomChara.Calls)
	if randomCharaCallVoicesCount == 0 {
		// ボイスが見つからない
		pc, fileName, line, _ := runtime.Caller(1)
		funcName := runtime.FuncForPC(pc).Name()
		logger.Error(err.Error(), fileName, funcName, line)
		return errors.New("ボイスがないぞ")
	}
	randomCharaVoiceIndex := rand.Intn(randomCharaCallVoicesCount)
	randomVoiceFileName := randomChara.Calls[randomCharaVoiceIndex].VoiceFileName

	// ランダム用のメモを作成
	b.randomCharaNameAndVoiceFileURL = map[string]CharaNameAndVoiceFilePath{}
	voiceFilePath := b.createVoiceFileURL(resourceBaseURL, randomChara.CharaID, randomVoiceFileName)
	b.randomCharaNameAndVoiceFileURL["RANDOM"] = CharaNameAndVoiceFilePath{CharaID: randomChara.CharaID, CharaName: randomChara.Name, VoiceFilePath: voiceFilePath}

	// 変換してSQSに送信
	for _, alarm := range alarmList {
		// 有効ではない時は何もしない
		if alarm.Enable == false {
			continue
		}

		// タイプごとにだし分ける
		if alarm.Type == "IOS_VOIP_PUSH_NOTIFICATION" {
			err := b.forIOSVoIPPushNotification(resourceBaseURL, alarm)
			if err != nil {
				// 不明なターゲット
				pc, fileName, line, _ := runtime.Caller(1)
				funcName := runtime.FuncForPC(pc).Name()
				logger.Error(err.Error(), fileName, funcName, line)
				continue
			}
		}
	}
	return nil
}

func (b *Batch) createVoiceFileURL(resourceBaseURL string, charaID string, voiceFileName string) string {
	return fmt.Sprintf("%s/%s/%s", resourceBaseURL, charaID, voiceFileName)
}

func (b *Batch) forIOSVoIPPushNotification(resourceBaseURL string, alarm entity2.Alarm) error {
	// AlarmInfoに変換
	alarmInfo := entity2.IOSVoIPPushAlarmInfoSQSMessage{}
	alarmInfo.AlarmID = alarm.AlarmID
	alarmInfo.UserID = alarm.UserID
	alarmInfo.SNSEndpointArn = alarm.Target

	//
	if alarm.CharaID == "" || alarm.CharaID == "RANDOM" {
		// CharaIDが無い場合 -> Charaとボイスをランダムにする
		alarmInfo.CharaID = b.randomCharaNameAndVoiceFileURL["RANDOM"].CharaID
		alarmInfo.CharaName = b.randomCharaNameAndVoiceFileURL["RANDOM"].CharaName
		alarmInfo.VoiceFileURL = b.randomCharaNameAndVoiceFileURL["RANDOM"].VoiceFilePath
	} else if alarm.CharaID != "" && alarm.CharaID != "RANDOM" && alarm.VoiceFileName != "" && alarm.VoiceFileName != "RANDOM" {
		// CharaIDがあり、VoiceFileNameがある場合 -> 指定のキャラを使い、指定のボイスを使用する
		alarmInfo.CharaID = alarm.CharaID
		alarmInfo.CharaName = alarm.CharaName
		alarmInfo.VoiceFileURL = b.createVoiceFileURL(resourceBaseURL, alarm.CharaID, alarm.VoiceFileName)
	} else {
		// CharaIDがあり、VoiceFileNameがない場合 -> 指定のキャラを使い、ボイスをランダム

		// メモ化が使われているかのチェック
		val, ok := b.randomCharaNameAndVoiceFileURL[alarm.CharaID]
		if ok {
			// キーがある場合
			alarmInfo.CharaID = val.CharaID
			alarmInfo.CharaName = val.CharaName
			alarmInfo.VoiceFileURL = val.VoiceFilePath
		} else {
			// キーがないのでDynamoDBから取得する
			chara, err := b.AWS.GetChara(alarm.CharaID)
			if err != nil {
				return err
			}
			charaCallVoicesCount := len(chara.Calls)
			if charaCallVoicesCount == 0 {
				return errors.New("error can not find voice")
			}
			charaCallVoiceIndex := rand.Intn(charaCallVoicesCount)
			charaCallVoiceFileName := chara.Calls[charaCallVoiceIndex].VoiceFileName
			b.randomCharaNameAndVoiceFileURL[alarm.CharaID] = CharaNameAndVoiceFilePath{CharaName: chara.Name, VoiceFilePath: charaCallVoiceFileName}

			// 設定
			alarmInfo.CharaID = chara.CharaID
			alarmInfo.CharaName = chara.Name
			alarmInfo.VoiceFileURL = b.createVoiceFileURL(resourceBaseURL, chara.CharaID, charaCallVoiceFileName)
		}
	}

	// SQSに送信
	return b.AWS.SendAlarmInfoToVoIPPushQueue(alarmInfo)
}
