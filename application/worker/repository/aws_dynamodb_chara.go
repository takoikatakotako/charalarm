package repository

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm-batch/database"
	"github.com/takoikatakotako/charalarm-batch/message"
	"math/rand"
	"time"
)

// GetChara キャラを取得する
func (a *AWS) GetChara(charaID string) (database.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return database.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.GetItemInput{
		TableName: aws.String(database.CharaTableName),
		Key: map[string]types.AttributeValue{
			database.CharaTableCharaID: &types.AttributeValueMemberS{
				Value: charaID,
			},
		},
	}
	resp, err := client.GetItem(context.Background(), input)
	if err != nil {
		return database.Chara{}, err
	}

	if len(resp.Item) == 0 {
		return database.Chara{}, fmt.Errorf(message.ItemNotFound)
	}

	// 取得結果をcharaに変換
	chara := database.Chara{}
	err = attributevalue.UnmarshalMap(resp.Item, &chara)
	if err != nil {
		return chara, err
	}

	return chara, nil
}

// GetRandomChara
// ランダムにキャラを1つ取得する, キャラ数が増えてきた場合は改良する
func (a *AWS) GetRandomChara() (database.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return database.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.ScanInput{
		TableName: aws.String("chara-table"),
		Limit:     aws.Int32(5),
	}
	output, err := client.Scan(context.Background(), input)
	if err != nil {
		return database.Chara{}, err
	}

	// ランダムに1件取得
	rand.Seed(time.Now().UnixNano())
	index := rand.Intn(len(output.Items))
	item := output.Items[index]

	// 取得結果をcharaに変換
	chara := database.Chara{}
	err = attributevalue.UnmarshalMap(item, &chara)
	if err != nil {
		return chara, err
	}

	return chara, nil
}
