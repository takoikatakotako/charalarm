package dynamodb

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	charalarm_config "github.com/takoikatakotako/charalarm-backend/config"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/util/logger"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"math/rand"
	"runtime"
	"time"
)

// GetChara キャラを取得する
func (d *DynamoDBRepository) GetChara(charaID string) (database.Chara, error) {
	// クライアント作成
	client, err := d.createDynamoDBClient()
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

// GetCharaList キャラ一覧を取得
func (d *DynamoDBRepository) GetCharaList() ([]database.Chara, error) {
	// クライアント作成
	client, err := d.createDynamoDBClient()
	if err != nil {
		return []database.Chara{}, err
	}

	// クエリ実行
	input := &dynamodb.ScanInput{
		TableName: aws.String("chara-table"),
	}
	output, err := client.Scan(context.Background(), input)
	if err != nil {
		return []database.Chara{}, err
	}

	// 取得結果を struct の配列に変換
	charaList := make([]database.Chara, 0)
	for _, item := range output.Items {
		chara := database.Chara{}
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
func (d *DynamoDBRepository) GetRandomChara() (database.Chara, error) {
	// クライアント作成
	client, err := d.createDynamoDBClient()
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

// Private Methods
func (d *DynamoDBRepository) createDynamoDBClient() (*dynamodb.Client, error) {
	ctx := context.Background()

	// DynamoDB クライアントの生成
	c, err := config.LoadDefaultConfig(ctx, config.WithRegion(charalarm_config.AWSRegion))
	if err != nil {
		fmt.Printf("load aws config: %s\n", err.Error())
		return nil, err
	}

	// LocalStackを使う場合
	if d.IsLocal {
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
	return dynamodb.NewFromConfig(c), nil
}
