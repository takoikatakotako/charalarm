package sqs

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/entity/sqs"
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
	sqsRepository := SQSRepository{IsLocal: true}
	err := sqsRepository.PurgeQueue()
	fmt.Print(err)

	exitVal := m.Run()

	// After Tests
	err = sqsRepository.PurgeQueue()
	fmt.Print(err)

	os.Exit(exitVal)
}

func TestSQSRepository_GetQueueURL(t *testing.T) {
	repository := SQSRepository{IsLocal: true}
	queueURL, err := repository.GetQueueURL(VoIPPushQueueName)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, "http://localhost:4566/000000000000/voip-push-queue.fifo", queueURL)
}

func TestSendMessage(t *testing.T) {
	repository := SQSRepository{IsLocal: true}

	// Purge
	err := repository.PurgeQueue()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	alarmID := uuid.New().String()
	userID := uuid.New().String()
	alarmInfo := sqs.IOSVoIPPushAlarmInfoSQSMessage{
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
	getAlarmInfo := sqs.IOSVoIPPushAlarmInfoSQSMessage{}
	body := *messages[0].Body
	_ = json.Unmarshal([]byte(body), &getAlarmInfo)
	assert.Equal(t, getAlarmInfo.AlarmID, alarmID)
}
