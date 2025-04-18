package service

import (
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type Chara struct {
	AWS         infrastructure.AWS
	Environment environment.Environment
}

// GetChara キャラクターを取得
func (c *Chara) GetChara(charaID string) (output.Chara, error) {
	chara, err := c.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}

	// BaseURLを取得
	baseURL := c.Environment.ResourceBaseURL
	return convertToCharaOutput(chara, baseURL), nil
}

// GetCharaList キャラクター一覧を取得
func (c *Chara) GetCharaList() ([]output.Chara, error) {
	charaList, err := c.AWS.GetCharaList()
	if err != nil {
		return []output.Chara{}, err
	}

	// BaseURLを取得
	baseURL := c.Environment.ResourceBaseURL

	// enable のものを抽出
	filteredCharaList := make([]database.Chara, 0)
	for _, chara := range charaList {
		if chara.Enable {
			filteredCharaList = append(filteredCharaList, chara)
		}
	}
	return convertToCharaOutputs(filteredCharaList, baseURL), nil
}
