package repository

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/google/uuid"
	"github.com/takoikatakotako/charalarm/batch/entity"
)

const (
	VoIPPushQueueName           = "voip-push-queue.fifo"
	VoIPPushDeadLetterQueueName = "voip-push-dead-letter-queue.fifo"
)

// Private Methods
func (a *AWS) createSQSClient() (*sqs.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}

	// Localの場合
	if a.Profile == "local" {
		return sqs.NewFromConfig(cfg, func(o *sqs.Options) {
			o.BaseEndpoint = aws.String(LocalstackEndpoint)
		}), nil
	}

	return sqs.NewFromConfig(cfg), nil
}

// GetQueueURL QueueのURLを取得する
func (a *AWS) GetQueueURL(queueName string) (string, error) {
	// SQSClient作成
	client, err := a.createSQSClient()
	if err != nil {
		return "", err
	}

	// QueueURLを取得
	input := &sqs.GetQueueUrlInput{
		QueueName: aws.String(queueName),
	}
	output, err := client.GetQueueUrl(context.Background(), input)
	if err != nil {
		return "", err
	}
	return *output.QueueUrl, nil
}

// SendAlarmInfoToVoIPPushQueue SQS
func (a *AWS) SendAlarmInfoToVoIPPushQueue(alarmInfo entity.IOSVoIPPushAlarmInfoSQSMessage) error {
	queueURL, err := a.GetQueueURL(VoIPPushQueueName)
	if err != nil {
		return err
	}
	messageGroupId := uuid.New().String()

	// メッセージ送信
	return a.sendAlarmInfoMessage(queueURL, messageGroupId, alarmInfo)
}

func (a *AWS) SendMessageToVoIPPushDeadLetterQueue(messageBody string) error {
	queueURL, err := a.GetQueueURL(VoIPPushDeadLetterQueueName)
	if err != nil {
		return err
	}
	messageGroupId := uuid.New().String()

	// メッセージ送信
	return a.sendMessage(queueURL, messageGroupId, messageBody)
}

func (a *AWS) ReceiveAlarmInfoMessage() ([]types.Message, error) {
	queueURL, err := a.GetQueueURL(VoIPPushQueueName)
	if err != nil {
		return []types.Message{}, err
	}
	return a.receiveMessage(queueURL)
}

func (a *AWS) PurgeQueue() error {
	queueURL := "http://localhost:4566/000000000000/voip-push-queue.fifo"

	// SQSClient作成
	client, err := a.createSQSClient()
	if err != nil {
		return err
	}

	// purge queue
	input := &sqs.PurgeQueueInput{
		QueueUrl: aws.String(queueURL),
	}
	_, err = client.PurgeQueue(context.Background(), input)
	return err
}

// //////////////////////////////////
// Private Methods
// //////////////////////////////////
func (a *AWS) sendAlarmInfoMessage(queueURL string, messageGroupId string, alarmInfo entity.IOSVoIPPushAlarmInfoSQSMessage) error {
	// decode
	jsonBytes, err := json.Marshal(alarmInfo)
	if err != nil {
		return err
	}
	messageBody := string(jsonBytes)

	return a.sendMessage(queueURL, messageGroupId, messageBody)
}

func (a *AWS) sendMessage(queueURL string, messageGroupId string, messageBody string) error {
	// SQSClient作成
	client, err := a.createSQSClient()
	if err != nil {
		return err
	}

	// sent message
	sMInput := &sqs.SendMessageInput{
		MessageAttributes: map[string]types.MessageAttributeValue{},
		MessageGroupId:    aws.String(messageGroupId),
		MessageBody:       aws.String(messageBody),
		QueueUrl:          aws.String(queueURL),
	}
	_, err = client.SendMessage(context.Background(), sMInput)
	return err
}

func (a *AWS) receiveMessage(queueURL string) ([]types.Message, error) {
	// SQSClient作成
	client, err := a.createSQSClient()
	if err != nil {
		return []types.Message{}, nil
	}

	// receive message
	timeout := 5
	gMInput := &sqs.ReceiveMessageInput{
		QueueUrl:            aws.String(queueURL),
		MaxNumberOfMessages: 10,
		VisibilityTimeout:   int32(timeout),
	}

	resp, err := client.ReceiveMessage(context.Background(), gMInput)
	if err != nil {
		return []types.Message{}, err
	}

	return resp.Messages, nil
}
