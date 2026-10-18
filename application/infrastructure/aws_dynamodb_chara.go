package infrastructure

import (
	"context"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"log/slog"
	"math/rand"
	"runtime"
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
		return database.Chara{}, fmt.Errorf(common.ItemNotFound)
	}

	// 取得結果をcharaに変換
	chara := database.Chara{}
	err = attributevalue.UnmarshalMap(resp.Item, &chara)
	if err != nil {
		return chara, err
	}

	return chara, nil
}

// UpsertChara キャラを作成/更新する (PutItem)
func (a *AWS) UpsertChara(chara database.Chara) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	av, err := attributevalue.MarshalMap(chara)
	if err != nil {
		return err
	}

	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(database.CharaTableName),
		Item:      av,
	})
	return err
}

// CreateChara キャラを新しく作る。同じ charaID のキャラがあれば ConditionalCheckFailedException を返す。
func (a *AWS) CreateChara(chara database.Chara) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	av, err := attributevalue.MarshalMap(chara)
	if err != nil {
		return err
	}

	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName:           aws.String(database.CharaTableName),
		Item:                av,
		ConditionExpression: aws.String("attribute_not_exists(" + database.CharaTableCharaID + ")"),
	})
	return err
}

// DeleteChara キャラを消す
func (a *AWS) DeleteChara(charaID string) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}

	_, err = client.DeleteItem(context.Background(), &dynamodb.DeleteItemInput{
		TableName: aws.String(database.CharaTableName),
		Key: map[string]types.AttributeValue{
			database.CharaTableCharaID: &types.AttributeValueMemberS{Value: charaID},
		},
	})
	return err
}

// GetCharaList キャラ一覧を取得
func (a *AWS) GetCharaList() ([]database.Chara, error) {
	// クライアント作成
	client, err := a.createDynamoDBClient()
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
			pc, fileName, _, _ := runtime.Caller(1)
			funcName := runtime.FuncForPC(pc).Name()
			slog.Error(err.Error(), slog.String("file", fileName), slog.String("func", funcName))
			continue
		}
		charaList = append(charaList, chara)
	}
	return charaList, nil
}

// GetRandomChara
// アラームに使えるキャラ (有効で、アラームのボイスがある) からランダムに1つ取得する。
// 準備中 (enable=false) のキャラや、ボイスをまだ用意していないキャラはアラームに使わない。
func (a *AWS) GetRandomChara() (database.Chara, error) {
	charaList, err := a.GetCharaList()
	if err != nil {
		return database.Chara{}, err
	}

	enableCharas := make([]database.Chara, 0, len(charaList))
	for _, chara := range charaList {
		if chara.Enable && len(chara.Calls) > 0 {
			enableCharas = append(enableCharas, chara)
		}
	}
	if len(enableCharas) == 0 {
		return database.Chara{}, errors.New("no chara for alarm")
	}
	return enableCharas[rand.Intn(len(enableCharas))], nil
}

// ListCharaTapLines はキャラのタップのセリフを返す。
func (a *AWS) ListCharaTapLines(charaID string) ([]database.CharaTapLine, error) {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return nil, err
	}

	lines := make([]database.CharaTapLine, 0)
	paginator := dynamodb.NewQueryPaginator(client, &dynamodb.QueryInput{
		TableName:              aws.String(database.CharaTapLineTableName),
		KeyConditionExpression: aws.String("#charaID = :charaID"),
		ExpressionAttributeNames: map[string]string{
			"#charaID": database.CharaTapLineTableCharaID,
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":charaID": &types.AttributeValueMemberS{Value: charaID},
		},
	})
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(context.Background())
		if err != nil {
			return nil, err
		}
		for _, item := range page.Items {
			line := database.CharaTapLine{}
			if err := attributevalue.UnmarshalMap(item, &line); err != nil {
				return nil, err
			}
			lines = append(lines, line)
		}
	}
	return lines, nil
}

// PutCharaTapLine はタップのセリフを1つ置く (作る・置き換える)。
func (a *AWS) PutCharaTapLine(line database.CharaTapLine) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}
	item, err := attributevalue.MarshalMap(line)
	if err != nil {
		return err
	}
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(database.CharaTapLineTableName),
		Item:      item,
	})
	return err
}

// DeleteCharaTapLine はタップのセリフを1つ消す。
func (a *AWS) DeleteCharaTapLine(charaID string, lineID string) error {
	client, err := a.createDynamoDBClient()
	if err != nil {
		return err
	}
	_, err = client.DeleteItem(context.Background(), &dynamodb.DeleteItemInput{
		TableName: aws.String(database.CharaTapLineTableName),
		Key: map[string]types.AttributeValue{
			database.CharaTapLineTableCharaID: &types.AttributeValueMemberS{Value: charaID},
			database.CharaTapLineTableLineID:  &types.AttributeValueMemberS{Value: lineID},
		},
	})
	return err
}
