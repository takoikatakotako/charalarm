package repository

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/api/util/logger"
	"github.com/takoikatakotako/charalarm/batch/message"
	"github.com/takoikatakotako/charalarm/repository/entity"
	"math/rand"
	"runtime"
	"time"
)

// GetChara キャラを取得する
func (a *AWS) GetChara(charaID string) (entity.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return entity.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.GetItemInput{
		TableName: aws.String(entity.CharaTableName),
		Key: map[string]types.AttributeValue{
			entity.CharaTableCharaID: &types.AttributeValueMemberS{
				Value: charaID,
			},
		},
	}
	resp, err := client.GetItem(context.Background(), input)
	if err != nil {
		return entity.Chara{}, err
	}

	if len(resp.Item) == 0 {
		return entity.Chara{}, fmt.Errorf(message.ItemNotFound)
	}

	// 取得結果をcharaに変換
	chara := entity.Chara{}
	err = attributevalue.UnmarshalMap(resp.Item, &chara)
	if err != nil {
		return chara, err
	}

	return chara, nil
}

// GetCharaList キャラ一覧を取得
func (a *AWS) GetCharaList() ([]entity.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return []entity.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.ScanInput{
		TableName: aws.String("chara-table"),
	}
	output, err := client.Scan(context.Background(), input)
	if err != nil {
		return []entity.Chara{}, err
	}

	// 取得結果を struct の配列に変換
	charaList := make([]entity.Chara, 0)
	for _, item := range output.Items {
		chara := entity.Chara{}
		err := attributevalue.UnmarshalMap(item, &chara)
		if err != nil {
			// Error
			pc, fileName, line, _ := runtime.Caller(1)
			funcName := runtime.FuncForPC(pc).Name()
			logger.Error(err.Error(), fileName, funcName, line)
			continue
		}
		charaList = append(charaList, chara)
	}
	return charaList, nil
}

// GetRandomChara
// ランダムにキャラを1つ取得する, キャラ数が増えてきた場合は改良する
func (a *AWS) GetRandomChara() (entity.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
	if err != nil {
		return entity.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.ScanInput{
		TableName: aws.String("chara-table"),
		Limit:     aws.Int32(5),
	}
	output, err := client.Scan(context.Background(), input)
	if err != nil {
		return entity.Chara{}, err
	}

	// ランダムに1件取得
	rand.Seed(time.Now().UnixNano())
	index := rand.Intn(len(output.Items))
	item := output.Items[index]

	// 取得結果をcharaに変換
	chara := entity.Chara{}
	err = attributevalue.UnmarshalMap(item, &chara)
	if err != nil {
		return chara, err
	}

	return chara, nil
}
