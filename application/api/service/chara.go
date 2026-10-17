package service

import (
	"log"
	"sort"

	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type Chara struct {
	AWS             infrastructure.AWS
	ResourceBaseURL string
}

// GetChara キャラクターを取得
func (c *Chara) GetChara(charaID string) (output.Chara, error) {
	chara, err := c.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}

	// タップのセリフはキャラを選んだときにだけ返す。読めなくてもキャラは返す (セリフがないだけ)
	tapLines, err := c.AWS.ListCharaTapLines(charaID)
	if err != nil {
		log.Printf("failed to list tap lines: chara=%s err=%v", charaID, err)
		tapLines = nil
	}

	// BaseURLを取得
	baseURL := c.ResourceBaseURL
	return convertToCharaOutput(chara, baseURL, tapLines), nil
}

// GetCharaList キャラクター一覧を取得
func (c *Chara) GetCharaList() ([]output.Chara, error) {
	charaList, err := c.AWS.GetCharaList()
	if err != nil {
		return []output.Chara{}, err
	}

	// BaseURLを取得
	baseURL := c.ResourceBaseURL

	// enable のものを抽出
	filteredCharaList := make([]database.Chara, 0)
	for _, chara := range charaList {
		if chara.Enable {
			filteredCharaList = append(filteredCharaList, chara)
		}
	}
	sortCharas(filteredCharaList)
	return convertToCharaOutputs(filteredCharaList, baseURL), nil
}

// sortCharas は表示順 (displayOrder の昇順、同じなら charaID 順) に並べる。
func sortCharas(charas []database.Chara) {
	sort.SliceStable(charas, func(i, j int) bool {
		if charas[i].DisplayOrder != charas[j].DisplayOrder {
			return charas[i].DisplayOrder < charas[j].DisplayOrder
		}
		return charas[i].CharaID < charas[j].CharaID
	})
}
