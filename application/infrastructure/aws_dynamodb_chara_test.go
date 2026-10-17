package infrastructure

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"testing"
)

func TestDynamoDBRepository_GetChara(t *testing.T) {
	repository := AWS{Profile: "local"}

	// com.charalarm.yui を取得できることを確認
	chara, err := repository.GetChara("com.charalarm.yui")
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, "com.charalarm.yui", chara.CharaID)
	assert.Equal(t, true, chara.Enable)
	assert.Equal(t, "井上結衣", chara.Name)
	assert.Equal(t, "com.charalarm.yui", chara.CharaID)
	assert.Equal(t, "イラストレーター", chara.Profiles[0].Title)
	assert.Equal(t, "さいもん", chara.Profiles[0].Name)
	assert.Equal(t, "https://twitter.com/simon_ns", chara.Profiles[0].URL)
	assert.Equal(t, "声優", chara.Profiles[1].Title)
	assert.Equal(t, "Mai", chara.Profiles[1].Name)
	assert.Equal(t, "https://twitter.com/mai_mizuiro", chara.Profiles[1].URL)
	assert.Equal(t, "スクリプト", chara.Profiles[2].Title)
	assert.Equal(t, "小旗ふたる！", chara.Profiles[2].Name)
	assert.Equal(t, "https://twitter.com/Kass_kobataku", chara.Profiles[2].URL)
	assert.Equal(t, "井上結衣さんのボイス15", chara.Calls[0].Message)
	assert.Equal(t, "com-charalarm-yui-15.caf", chara.Calls[0].VoiceFileName)
	assert.Equal(t, "井上結衣さんのボイス15", chara.Calls[0].Message)
	assert.Equal(t, "normal.png", chara.Expressions["normal"].ImageFileNames[0])
	assert.Equal(t, "com-charalarm-yui-1.caf", chara.Expressions["normal"].VoiceFileNames[0])

	// fmt.Println(chara.Expressions["normal"])

	// 	assert.Equal(t, "xxx", chara.Expressions["normal"].ImageFileNames[0])

}

func TestGetCharaNotFound(t *testing.T) {
	repository := AWS{Profile: "local"}

	// com.charalarm.not.found を取得できないことを確認
	_, err := repository.GetChara("com.charalarm.not.found")
	assert.Error(t, fmt.Errorf("item not found"), err)
}

func TestGetCharaList(t *testing.T) {
	repository := AWS{Profile: "local"}

	charaList, err := repository.GetCharaList()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert (最初から入っている yui / momiji / zundamon の3体がいる。
	// ほかのテストが一時的にキャラを足すことがあるので、件数は決め打ちしない)
	charaIDs := make([]string, 0, len(charaList))
	for _, chara := range charaList {
		charaIDs = append(charaIDs, chara.CharaID)
	}
	assert.Subset(t, charaIDs, []string{"com.charalarm.yui", "com.senpu-ki-soft.momiji", "jp.zunko.zundamon"})
}

func TestGetRandomChara(t *testing.T) {
	repository := AWS{Profile: "local"}

	chara, err := repository.GetRandomChara()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.NotEqual(t, len(chara.CharaID), 0)
}

func TestCharaTapLines(t *testing.T) {
	repository := AWS{Profile: "local"}
	const charaID = "com.example.taplines"

	line := database.CharaTapLine{
		CharaID: charaID, ID: "a1b2c3d4e5f6", Text: "おはようございます。", Theme: "morning", Language: "ja",
		When: database.CharaTapLineWhen{Hours: []int{5, 11}},
	}
	assert.NoError(t, repository.PutCharaTapLine(line))
	assert.NoError(t, repository.PutCharaTapLine(database.CharaTapLine{CharaID: charaID, ID: "b1b2c3d4e5f6", Text: "Hello.", Language: "en"}))

	lines, err := repository.ListCharaTapLines(charaID)
	assert.NoError(t, err)
	assert.Len(t, lines, 2)
	assert.Equal(t, line, lines[0])

	assert.NoError(t, repository.DeleteCharaTapLine(charaID, "a1b2c3d4e5f6"))
	assert.NoError(t, repository.DeleteCharaTapLine(charaID, "b1b2c3d4e5f6"))
	lines, err = repository.ListCharaTapLines(charaID)
	assert.NoError(t, err)
	assert.Empty(t, lines)
}
