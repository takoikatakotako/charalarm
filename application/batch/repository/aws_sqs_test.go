package repository

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/batch/entity"
	"os"
	"testing"
)

// func TestCreateVoipPlatformEndpoint(t *testing.T) {
// 	repository := SNSRepository{IsLocal: true}

// 	token := uuid.New().String()
// 	response, err := repository.CreateIOSVoipPushPlatformEndpoint(token)
// 	if err != nil {
// 		t.Errorf("unexpected error: %v", err)
// 	}

// 	assert.NotEqual(t, len(response.EndpointArn), 0)
// }

func TestMain(m *testing.M) {
	// Before Tests
	repository := AWS{Profile: "local"}
	err := repository.PurgeQueue()
	fmt.Print(err)

	exitVal := m.Run()

	// After Tests
	err = repository.PurgeQueue()
	fmt.Print(err)

	os.Exit(exitVal)
}

func TestSQSRepository_GetQueueURL(t *testing.T) {
	repository := AWS{Profile: "local"}
	queueURL, err := repository.GetQueueURL(VoIPPushQueueName)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, "http://sqs.ap-northeast-1.localhost.localstack.cloud:4566/000000000000/voip-push-queue.fifo", queueURL)
}

func TestSendMessage(t *testing.T) {
	repository := AWS{Profile: "local"}

	// Purge
	err := repository.PurgeQueue()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	alarmID := uuid.New().String()
	userID := uuid.New().String()
	alarmInfo := entity.IOSVoIPPushAlarmInfoSQSMessage{
		AlarmID:        alarmID,
		UserID:         userID,
		SNSEndpointArn: "dummy",
		CharaName:      "xxxx",
		VoiceFileURL:   "xxxxx",
	}

	err = repository.SendAlarmInfoToVoIPPushQueue(alarmInfo)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	messages, err := repository.ReceiveAlarmInfoMessage()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, 1, len(messages))
	getAlarmInfo := entity.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	_ = json.Unmarshal([]byte(body), &getAlarmInfo)
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
}
