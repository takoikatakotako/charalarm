package converter

import (
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/entity/request"
	"testing"
)

func TestMaskAuthToken(t *testing.T) {
	result := maskAuthToken("20f0c1cd-9c2a-411a-878c-9bd0bb15dc35")

	// Assert
	assert.Equal(t, "20**********************************", result)
}

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

	responseChara := DatabaseCharaToResponseChara(databaseChara, baseURL)
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

// request.Alarm から database.Alarm への変換ができる
func TestRequestAlarmToDatabaseAlarm(t *testing.T) {
	alarmID := uuid.New().String()
	userID := uuid.New().String()
	const alarmType = "IOS_VOIP_PUSH_NOTIFICATION"
	const alarmEnable = true
	var alarmName = "alarmName"
	const alarmHour = 8
	const alarmMinute = 30
	const alarmTimeDifference = float32(9.0)
	const charaID = "charaID"
	const charaName = "charaName"
	const voiceFileURL = "voiceFileURL"
	const sunday = true
	const monday = false
	const tuesday = false
	const wednesday = true
	const thursday = false
	const friday = false
	const saturday = true

	const target = "target"

	requestAlarm := request.Alarm{
		AlarmID:        alarmID,
		UserID:         userID,
		Type:           alarmType,
		Enable:         alarmEnable,
		Name:           alarmName,
		Hour:           alarmHour,
		Minute:         alarmMinute,
		TimeDifference: alarmTimeDifference,

		// Chara Info
		CharaID:       charaID,
		CharaName:     charaName,
		VoiceFileName: voiceFileURL,

		// Weekday
		Sunday:    sunday,
		Monday:    monday,
		Tuesday:   tuesday,
		Wednesday: wednesday,
		Thursday:  thursday,
		Friday:    friday,
		Saturday:  saturday,
	}

	databaseAlarm := RequestAlarmToDatabaseAlarm(requestAlarm, target)

	assert.Equal(t, alarmID, databaseAlarm.AlarmID)
	assert.Equal(t, userID, databaseAlarm.UserID)
	assert.Equal(t, alarmType, databaseAlarm.Type)
	assert.Equal(t, target, databaseAlarm.Target)
	assert.Equal(t, alarmName, databaseAlarm.Name)
	assert.Equal(t, 23, databaseAlarm.Hour)
	assert.Equal(t, 30, databaseAlarm.Minute)
	assert.Equal(t, alarmTimeDifference, databaseAlarm.TimeDifference)
	assert.Equal(t, charaID, databaseAlarm.CharaID)
	assert.Equal(t, charaName, databaseAlarm.CharaName)
	assert.Equal(t, voiceFileURL, databaseAlarm.VoiceFileName)
	assert.Equal(t, true, databaseAlarm.Sunday)
	assert.Equal(t, true, databaseAlarm.Monday)
	assert.Equal(t, false, databaseAlarm.Tuesday)
	assert.Equal(t, false, databaseAlarm.Wednesday)
	assert.Equal(t, true, databaseAlarm.Thursday)
	assert.Equal(t, false, databaseAlarm.Friday)
	assert.Equal(t, false, databaseAlarm.Saturday)
}

// request.Alarm から database.Alarm への変換ができる
func TestRequestAlarmToDatabaseAlarmFeatureTimeDifference(t *testing.T) {
	// 日本(UTC+9)の8:13はUTCは前日の23:13
	requestAlarm1 := request.Alarm{
		Hour:           8,
		Minute:         13,
		TimeDifference: 9,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm1 := RequestAlarmToDatabaseAlarm(requestAlarm1, "target1")
	assert.Equal(t, 23, databaseAlarm1.Hour)
	assert.Equal(t, 13, databaseAlarm1.Minute)
	assert.Equal(t, false, databaseAlarm1.Sunday)
	assert.Equal(t, true, databaseAlarm1.Monday)
	assert.Equal(t, false, databaseAlarm1.Tuesday)
	assert.Equal(t, true, databaseAlarm1.Wednesday)
	assert.Equal(t, false, databaseAlarm1.Thursday)
	assert.Equal(t, false, databaseAlarm1.Friday)
	assert.Equal(t, true, databaseAlarm1.Saturday)

	// 日本(UTC+9)の9:18はUTCは当日の0:18
	requestAlarm2 := request.Alarm{
		Hour:           9,
		Minute:         18,
		TimeDifference: 9,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm2 := RequestAlarmToDatabaseAlarm(requestAlarm2, "target2")
	assert.Equal(t, 0, databaseAlarm2.Hour)
	assert.Equal(t, 18, databaseAlarm2.Minute)
	assert.Equal(t, true, databaseAlarm2.Sunday)
	assert.Equal(t, false, databaseAlarm2.Monday)
	assert.Equal(t, true, databaseAlarm2.Tuesday)
	assert.Equal(t, false, databaseAlarm2.Wednesday)
	assert.Equal(t, false, databaseAlarm2.Thursday)
	assert.Equal(t, true, databaseAlarm2.Friday)
	assert.Equal(t, false, databaseAlarm2.Saturday)

	// イギリス(UTC+0)の0:0はUTCは当日の0:0
	requestAlarm3 := request.Alarm{
		Hour:           0,
		Minute:         0,
		TimeDifference: 0,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm3 := RequestAlarmToDatabaseAlarm(requestAlarm3, "target3")
	assert.Equal(t, 0, databaseAlarm3.Hour)
	assert.Equal(t, 0, databaseAlarm3.Minute)
	assert.Equal(t, true, databaseAlarm3.Sunday)
	assert.Equal(t, false, databaseAlarm3.Monday)
	assert.Equal(t, true, databaseAlarm3.Tuesday)
	assert.Equal(t, false, databaseAlarm3.Wednesday)
	assert.Equal(t, false, databaseAlarm3.Thursday)
	assert.Equal(t, true, databaseAlarm3.Friday)
	assert.Equal(t, false, databaseAlarm3.Saturday)

	// 	アメリカ合衆国	ロサンゼルス(UTC-8)の19:45はUTCは1日後の3:45
	requestAlarm4 := request.Alarm{
		Hour:           19,
		Minute:         45,
		TimeDifference: -8,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm4 := RequestAlarmToDatabaseAlarm(requestAlarm4, "target4")
	assert.Equal(t, 3, databaseAlarm4.Hour)
	assert.Equal(t, 45, databaseAlarm4.Minute)
	assert.Equal(t, false, databaseAlarm4.Sunday)
	assert.Equal(t, true, databaseAlarm4.Monday)
	assert.Equal(t, false, databaseAlarm4.Tuesday)
	assert.Equal(t, false, databaseAlarm4.Wednesday)
	assert.Equal(t, true, databaseAlarm4.Thursday)
	assert.Equal(t, false, databaseAlarm4.Friday)
	assert.Equal(t, true, databaseAlarm4.Saturday)

	// イギリス(UTC+0)の08:12はUTCは当日の08:20
	requestAlarm5 := request.Alarm{
		Hour:           8,
		Minute:         12,
		TimeDifference: 0,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm5 := RequestAlarmToDatabaseAlarm(requestAlarm5, "target5")
	assert.Equal(t, 8, databaseAlarm5.Hour)
	assert.Equal(t, 12, databaseAlarm5.Minute)
	assert.Equal(t, true, databaseAlarm5.Sunday)
	assert.Equal(t, false, databaseAlarm5.Monday)
	assert.Equal(t, true, databaseAlarm5.Tuesday)
	assert.Equal(t, false, databaseAlarm5.Wednesday)
	assert.Equal(t, false, databaseAlarm5.Thursday)
	assert.Equal(t, true, databaseAlarm5.Friday)
	assert.Equal(t, false, databaseAlarm5.Saturday)

	// 日本の(UTC+9)の23:48はUTCは当日の14:48
	requestAlarm6 := request.Alarm{
		Hour:           23,
		Minute:         48,
		TimeDifference: 9,

		// Weekday
		Sunday:    true,
		Monday:    false,
		Tuesday:   true,
		Wednesday: false,
		Thursday:  false,
		Friday:    true,
		Saturday:  false,
	}

	databaseAlarm6 := RequestAlarmToDatabaseAlarm(requestAlarm6, "target6")
	assert.Equal(t, 14, databaseAlarm6.Hour)
	assert.Equal(t, 48, databaseAlarm6.Minute)
	assert.Equal(t, true, databaseAlarm6.Sunday)
	assert.Equal(t, false, databaseAlarm6.Monday)
	assert.Equal(t, true, databaseAlarm6.Tuesday)
	assert.Equal(t, false, databaseAlarm6.Wednesday)
	assert.Equal(t, false, databaseAlarm6.Thursday)
	assert.Equal(t, true, databaseAlarm6.Friday)
	assert.Equal(t, false, databaseAlarm6.Saturday)
}

func TestDatabaseAlarmToResponseAlarm(t *testing.T) {
	//　TODO テストを追加
}
