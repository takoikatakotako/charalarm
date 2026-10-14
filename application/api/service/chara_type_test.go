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

func TestConvertToCharaAppearances(t *testing.T) {
	baseURL := "https://resource.example.com"
	vrm := output.CharaAppearance{Type: database.AppearanceTypeVRM, ModelFileURL: "https://resource.example.com/com.charalarm.shiori/shiori.vrm"}
	illustration := output.CharaAppearance{Type: database.AppearanceTypeIllustration}
	expressions := map[string]database.CharaExpression{"normal": {ImageFileNames: []string{"normal.png"}}}

	t.Run("立ち絵だけのキャラ", func(t *testing.T) {
		assert.Equal(t, []output.CharaAppearance{illustration},
			convertToCharaAppearances(database.Chara{CharaID: "com.charalarm.yui", Expressions: expressions}, baseURL))
	})

	t.Run("VRM と立ち絵の両方があれば両方。既定 (vrm) が先頭", func(t *testing.T) {
		assert.Equal(t, []output.CharaAppearance{vrm, illustration},
			convertToCharaAppearances(database.Chara{
				CharaID: "com.charalarm.shiori", AppearanceType: database.AppearanceTypeVRM, VRMFileName: "shiori.vrm", Expressions: expressions,
			}, baseURL))
	})

	t.Run("既定が立ち絵なら立ち絵が先頭", func(t *testing.T) {
		assert.Equal(t, []output.CharaAppearance{illustration, vrm},
			convertToCharaAppearances(database.Chara{
				CharaID: "com.charalarm.shiori", AppearanceType: database.AppearanceTypeIllustration, VRMFileName: "shiori.vrm", Expressions: expressions,
			}, baseURL))
	})

	t.Run("VRM だけのキャラ", func(t *testing.T) {
		assert.Equal(t, []output.CharaAppearance{vrm},
			convertToCharaAppearances(database.Chara{CharaID: "com.charalarm.shiori", AppearanceType: database.AppearanceTypeVRM, VRMFileName: "shiori.vrm"}, baseURL))
	})
}
