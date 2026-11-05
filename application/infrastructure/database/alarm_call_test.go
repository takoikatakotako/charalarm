package database

import (
	"testing"

	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAlarmCallIsValid(t *testing.T) {
	for _, limit := range []int{30, 60, 90, 120, 180} {
		assert.True(t, AlarmCall{TimeLimit: limit}.IsValid(), limit)
	}
	for _, limit := range []int{0, 45, 181, -1} {
		assert.False(t, AlarmCall{TimeLimit: limit}.IsValid(), limit)
	}
}

func TestAlarmCallDynamoDB(t *testing.T) {
	t.Run("設定の無いアラームは call を書かない（古いアラームと同じ形）", func(t *testing.T) {
		av, err := attributevalue.MarshalMap(Alarm{AlarmID: "a"})
		require.NoError(t, err)
		_, ok := av["call"]
		assert.False(t, ok)

		var alarm Alarm
		require.NoError(t, attributevalue.UnmarshalMap(av, &alarm))
		assert.Nil(t, alarm.Call)
	})

	t.Run("設定のあるアラームは読み書きできる", func(t *testing.T) {
		call := &AlarmCall{TimeLimit: 90, Schedule: true, Weather: true, News: false}
		av, err := attributevalue.MarshalMap(Alarm{AlarmID: "a", Call: call})
		require.NoError(t, err)
		var alarm Alarm
		require.NoError(t, attributevalue.UnmarshalMap(av, &alarm))
		assert.Equal(t, call, alarm.Call)
	})
}
