package notification

import (
	"strconv"

	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// iOS は中身を [String: String] として読むので、値はすべて文字列にする（入れ子があると古いアプリが読めない）。
type IOSVoIPPushSNSMessage struct {
	CharaID      string `json:"charaID"`
	CharaName    string `json:"charaName"`
	VoiceFileURL string `json:"voiceFileURL"`

	// アラームの電話（AI 会話）の設定。アラームに設定が無ければ入れない（アプリ共通の設定を使う）
	CallTimeLimit string `json:"callTimeLimit,omitempty"` // 秒
	CallSchedule  string `json:"callSchedule,omitempty"`  // "true" / "false"
	CallWeather   string `json:"callWeather,omitempty"`
	CallNews      string `json:"callNews,omitempty"`
}

// SetCall はアラームの電話の設定を入れる。nil なら何も入れない。
func (m *IOSVoIPPushSNSMessage) SetCall(call *database.AlarmCall) {
	if call == nil {
		return
	}
	m.CallTimeLimit = strconv.Itoa(call.TimeLimit)
	m.CallSchedule = strconv.FormatBool(call.Schedule)
	m.CallWeather = strconv.FormatBool(call.Weather)
	m.CallNews = strconv.FormatBool(call.News)
}
