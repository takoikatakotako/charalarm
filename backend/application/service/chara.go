package service

import (
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/entity/response"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/environment_variable"
	"github.com/takoikatakotako/charalarm-backend/util/converter"
)

type CharaService struct {
	DynamoDBRepository            dynamodb.DynamoDBRepositoryInterface
	EnvironmentVariableRepository environment_variable.EnvironmentVariableRepository
}

// GetChara キャラクターを取得
func (s *CharaService) GetChara(charaID string) (response.Chara, error) {
	chara, err := s.DynamoDBRepository.GetChara(charaID)
	if err != nil {
		return response.Chara{}, err
	}

	// BaseURLを取得
	baseURL, err := s.EnvironmentVariableRepository.GetResourceBaseURL()
	if err != nil {
		return response.Chara{}, err
	}

	return converter.DatabaseCharaToResponseChara(chara, baseURL), nil
}

// GetCharaList キャラクター一覧を取得
func (s *CharaService) GetCharaList() ([]response.Chara, error) {
	charaList, err := s.DynamoDBRepository.GetCharaList()
	if err != nil {
		return []response.Chara{}, err
	}

	// BaseURLを取得
	baseURL, err := s.EnvironmentVariableRepository.GetResourceBaseURL()
	if err != nil {
		return []response.Chara{}, err
	}

	// enable のものを抽出
	filteredCharaList := make([]database.Chara, 0)
	for _, chara := range charaList {
		if chara.Enable {
			filteredCharaList = append(filteredCharaList, chara)
		}
	}
	return converter.DatabaseCharaListToResponseCharaList(filteredCharaList, baseURL), nil
}
