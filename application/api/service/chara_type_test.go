package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestSortCharas(t *testing.T) {
	charas := []database.Chara{
		{CharaID: "jp.zunko.zundamon", DisplayOrder: 30},
		{CharaID: "com.senpu-ki-soft.momiji"},
		{CharaID: "com.charalarm.new", DisplayOrder: -10},
		{CharaID: "com.charalarm.yui"},
	}
	sortCharas(charas)

	ids := make([]string, 0, len(charas))
	for _, c := range charas {
		ids = append(ids, c.CharaID)
	}
	assert.Equal(t, []string{"com.charalarm.new", "com.charalarm.yui", "com.senpu-ki-soft.momiji", "jp.zunko.zundamon"}, ids)
}

func TestConvertToCharaAppearance(t *testing.T) {
	baseURL := "https://resource.example.com"

	assert.Equal(t, output.CharaAppearance{Type: database.AppearanceTypeIllustration},
		convertToCharaAppearance(database.Chara{CharaID: "com.charalarm.yui"}, baseURL))

	assert.Equal(t, output.CharaAppearance{
		Type:         database.AppearanceTypeVRM,
		ModelFileURL: "https://resource.example.com/com.charalarm.new/model.vrm",
	}, convertToCharaAppearance(database.Chara{
		CharaID:        "com.charalarm.new",
		AppearanceType: database.AppearanceTypeVRM,
		VRMFileName:    "model.vrm",
	}, baseURL))
}
