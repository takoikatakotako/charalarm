package service

import (
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/environment"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"testing"
)

func TestCharalarmList(t *testing.T) {
	// AWS Repository
	awsRepository := infrastructure.AWS{Profile: "local"}
	environmentRepository := environment.Environment{}

	service := Chara{
		AWS:         awsRepository,
		Environment: environmentRepository,
	}

	// トークン作成
	charaList, err := service.GetCharaList()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.NotEqual(t, 0, len(charaList))
}
