package service

import (
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
	"testing"
)

func TestDatabaseCharaToResponseChara(t *testing.T) {
	baseURL := "https://swiswiswift.com"

	databaseChara := database.Chara{
		CharaID:     "com.example.chara",
		Enable:      false,
		Name:        "Snorlax",
		Description: "Snorlax",
		Profiles: []database.CharaProfile{
			{
				Title: "プログラマ",
				Name:  "かびごん小野",
				URL:   "https://twitter.com/takoikatakotako",
			},
		},
		Expressions: map[string]database.CharaExpression{
			"normal": {
				ImageFileNames: []string{"normal1.png", "normal2.png"},
				VoiceFileNames: []string{"voice1.mp3", "voice2.mp3"},
			},
		},
		Calls: []database.CharaCall{
			{
				Message:       "カビゴン語でおはよう",
				VoiceFileName: "hello.caf",
			},
		},
	}

	responseChara := convertToCharaOutput(databaseChara, baseURL)
	assert.Equal(t, databaseChara.CharaID, responseChara.CharaID)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/normal1.png", responseChara.Expression["normal"].ImageFileURLs[0])
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/normal2.png", responseChara.Expression["normal"].ImageFileURLs[1])
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/voice1.mp3", responseChara.Expression["normal"].VoiceFileURLs[0])
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/voice2.mp3", responseChara.Expression["normal"].VoiceFileURLs[1])
	assert.Equal(t, "hello.caf", responseChara.Calls[0].VoiceFileName)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/hello.caf", responseChara.Calls[0].VoiceFileURL)
	assert.Equal(t, 5, len(responseChara.Resources))
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/normal1.png", responseChara.Resources[0].FileURL)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/normal2.png", responseChara.Resources[1].FileURL)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/voice1.mp3", responseChara.Resources[2].FileURL)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/voice2.mp3", responseChara.Resources[3].FileURL)
	assert.Equal(t, "https://swiswiswift.com/com.example.chara/hello.caf", responseChara.Resources[4].FileURL)
}
