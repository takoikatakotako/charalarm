package service2

import (
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-api/repository2"
	"testing"
)

func TestCharalarmList(t *testing.T) {
	// AWS Repository
	awsRepository := repository2.AWS{Profile: "local"}
	environmentRepository := repository2.Environment{IsLocal: true}

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
