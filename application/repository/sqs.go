package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/google/uuid"
	charalarm_config "github.com/takoikatakotako/charalarm-backend/config"
	sqs_entity "github.com/takoikatakotako/charalarm-backend/sqs"
	"os"
)

const (
	VoIPPushQueueName = "voip-push-queue.fifo"
)

type SQSRepository struct {
	IsLocal bool
}

func (s *SQSRepository) createSQSClient() (*sqs.Client, error) {
	ctx := context.Background()

	// SQS クライアントの生成
	c, err := config.LoadDefaultConfig(ctx, config.WithRegion(charalarm_config.AWSRegion))
	if err != nil {
		fmt.Printf("load aws config: %s\n", err.Error())
		return nil, err
	}

	// LocalStackを使う場合
	if s.IsLocal {
		c.EndpointResolverWithOptions = aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			return aws.Endpoint{
				URL:           charalarm_config.LocalstackEndpoint,
				SigningRegion: charalarm_config.AWSRegion,
			}, nil
		})
		if err != nil {
			fmt.Printf("unable to load SDK config, %v", err)
			return nil, err
		}
	}
	return sqs.NewFromConfig(c), nil
}

// GetQueueURL QueueのURLを取得する
func (s *SQSRepository) GetQueueURL(queueName string) (string, error) {
	// SQSClient作成
	client, err := s.createSQSClient()
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
func (s *SQSRepository) SendAlarmInfoToVoIPPushQueue(alarmInfo sqs_entity.AlarmInfo) error {
	queueURL, err := s.GetQueueURL(VoIPPushQueueName)
	if err != nil {
		return err
	}
	messageGroupId := uuid.New().String()

	// メッセージ送信
	return s.sendAlarmInfoMessage(queueURL, messageGroupId, alarmInfo)
}

func (s *SQSRepository) SendMessageToVoIPPushDeadLetterQueue(messageBody string) error {
	queueURL, err := s.getVoIPPushDeadLetterQueueURL()
	if err != nil {
		return err
	}
	messageGroupId := uuid.New().String()

	// メッセージ送信
	return s.sendMessage(queueURL, messageGroupId, messageBody)
}

func (s *SQSRepository) ReceiveAlarmInfoMessage() ([]types.Message, error) {
	queueURL := "http://localhost:4566/000000000000/voip-push-queue.fifo"
	return s.recieveMessage(queueURL)
}

func (s *SQSRepository) PurgeQueue() error {
	queueURL := "http://localhost:4566/000000000000/voip-push-queue.fifo"

	// SQSClient作成
	client, err := s.createSQSClient()
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

////////////////////////////////////
// Private Methods
////////////////////////////////////
func (s *SQSRepository) sendAlarmInfoMessage(queueURL string, messageGroupId string, alarmInfo sqs_entity.AlarmInfo) error {
	// decode
	jsonBytes, err := json.Marshal(alarmInfo)
	if err != nil {
		return err
	}
	messageBody := string(jsonBytes)

	return s.sendMessage(queueURL, messageGroupId, messageBody)
}

func (s *SQSRepository) sendMessage(queueURL string, messageGroupId string, messageBody string) error {
	// SQSClient作成
	client, err := s.createSQSClient()
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

func (s *SQSRepository) recieveMessage(queueURL string) ([]types.Message, error) {
	// SQSClient作成
	client, err := s.createSQSClient()
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

// Get Queue URL
func (s *SQSRepository) getVoIPPushQueueURL() (string, error) {
	if s.IsLocal {
		return charalarm_config.LocalVoIPPushQueueURL, nil
	} else {
		voIPPushQueueURL, ok := os.LookupEnv(charalarm_config.VoIPPushQueueURLKey)
		if ok {
			return voIPPushQueueURL, nil
		} else {
			return "", errors.New("VoIPPushQueueUrl is not found")
		}
	}
}

func (s *SQSRepository) getVoIPPushDeadLetterQueueURL() (string, error) {
	if s.IsLocal {
		return charalarm_config.LocalVoIPPushDeadLetterQueueURL, nil
	} else {
		voIPPushDeadLetterQueueURL, ok := os.LookupEnv(charalarm_config.VoIPPushDeadLetterQueueURLKey)
		if ok {
			return voIPPushDeadLetterQueueURL, nil
		} else {
			return "", errors.New("VoIPPushDeadLetterQueueUrl is not found")
		}
	}
}
