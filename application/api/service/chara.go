package service

import (
	"github.com/takoikatakotako/charalarm-api/entity/database"
	"github.com/takoikatakotako/charalarm-api/entity/response"
	"github.com/takoikatakotako/charalarm-api/repository"
	"github.com/takoikatakotako/charalarm-api/util/converter"
)

type Chara struct {
	AWS          repository.AWS
	Environment2 repository.Environment
}

// GetChara キャラクターを取得
func (c *Chara) GetChara(charaID string) (response.Chara, error) {
	chara, err := c.AWS.GetChara(charaID)
	if err != nil {
		return response.Chara{}, err
	}

	// BaseURLを取得
	baseURL := c.Environment2.ResourceBaseURL
	return converter.DatabaseCharaToResponseChara(chara, baseURL), nil
}

// GetCharaList キャラクター一覧を取得
func (c *Chara) GetCharaList() ([]response.Chara, error) {
	charaList, err := c.AWS.GetCharaList()
	if err != nil {
		return []response.Chara{}, err
	}

	// BaseURLを取得
	baseURL := c.Environment2.ResourceBaseURL

	// enable のものを抽出
	filteredCharaList := make([]database.Chara, 0)
	for _, chara := range charaList {
		if chara.Enable {
			filteredCharaList = append(filteredCharaList, chara)
		}
	}
	return converter.DatabaseCharaListToResponseCharaList(filteredCharaList, baseURL), nil
}
