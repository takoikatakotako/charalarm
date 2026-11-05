package notification

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestIOSVoIPPushSNSMessageCall(t *testing.T) {
	t.Run("設定のあるアラームは、文字列の項目として平らに入れる", func(t *testing.T) {
		m := IOSVoIPPushSNSMessage{CharaID: "com.charalarm.yui", CharaName: "井上結衣", VoiceFileURL: "https://example.com/a.caf"}
		m.SetCall(&database.AlarmCall{TimeLimit: 60, Schedule: true, Weather: false, News: true})
		data, err := json.Marshal(m)
		require.NoError(t, err)

		// iOS は [String: String] として読むので、値はすべて文字列
		var payload map[string]string
		require.NoError(t, json.Unmarshal(data, &payload))
		assert.Equal(t, "60", payload["callTimeLimit"])
		assert.Equal(t, "true", payload["callSchedule"])
		assert.Equal(t, "false", payload["callWeather"])
		assert.Equal(t, "true", payload["callNews"])
		assert.Equal(t, "井上結衣", payload["charaName"])
	})

	t.Run("設定の無いアラームは、項目を入れない", func(t *testing.T) {
		m := IOSVoIPPushSNSMessage{CharaID: "com.charalarm.yui", CharaName: "井上結衣", VoiceFileURL: "https://example.com/a.caf"}
		m.SetCall(nil)
		data, err := json.Marshal(m)
		require.NoError(t, err)
		assert.Equal(t, `{"charaID":"com.charalarm.yui","charaName":"井上結衣","voiceFileURL":"https://example.com/a.caf"}`, string(data))
	})
}
