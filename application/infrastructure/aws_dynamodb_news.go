package infrastructure

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// ScanNews お知らせを全件取得する (件数が少ない前提で Scan)
func (a *AWS) ScanNews() ([]database.News, error) {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return nil, err
	}

	ctx := context.Background()
	output, err := client.Scan(ctx, &dynamodb.ScanInput{
		TableName: aws.String(database.NewsTableName),
	})
	if err != nil {
		return nil, err
	}

	newsList := make([]database.News, 0, len(output.Items))
	for _, item := range output.Items {
		news := database.News{}
		if err := attributevalue.UnmarshalMap(item, &news); err != nil {
			continue
		}
		newsList = append(newsList, news)
	}
	return newsList, nil
}

// InsertNews お知らせを追加する
func (a *AWS) InsertNews(news database.News) error {
	if err := database.ValidateNews(news); err != nil {
		return err
	}

	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	av, err := attributevalue.MarshalMap(news)
	if err != nil {
		fmt.Printf("dynamodb marshal: %s\n", err.Error())
		return err
	}

	ctx := context.Background()
	_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(database.NewsTableName),
		Item:      av,
	})
	if err != nil {
		fmt.Printf("put item: %s\n", err.Error())
		return err
	}
	return nil
}

// DeleteNews お知らせを削除する
func (a *AWS) DeleteNews(newsID string) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	ctx := context.Background()
	_, err = client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(database.NewsTableName),
		Key: map[string]types.AttributeValue{
			database.NewsTableNewsID: &types.AttributeValueMemberS{
				Value: newsID,
			},
		},
	})
	if err != nil {
		return err
	}
	return nil
}
