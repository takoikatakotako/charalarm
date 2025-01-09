package service

import (
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/repository/dynamodb"
	"github.com/takoikatakotako/charalarm-backend/repository/environment_variable"
	"testing"
)

func TestCharalarmList(t *testing.T) {
	dynamoDBRepository := &dynamodb.DynamoDBRepository{IsLocal: true}
	environmentVariableRepository := environment_variable.EnvironmentVariableRepository{IsLocal: true}

	service := CharaService{
		DynamoDBRepository:            dynamoDBRepository,
		EnvironmentVariableRepository: environmentVariableRepository,
	}

	// トークン作成
	charaList, err := service.GetCharaList()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.NotEqual(t, 0, len(charaList))
}
