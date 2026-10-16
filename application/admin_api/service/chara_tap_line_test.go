package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func TestCheckTapLineSensitive(t *testing.T) {
	assert.NoError(t, checkTapLineSensitive("メリークリスマス！今日は少しだけ、のんびりしましょうね。"))
	assert.NoError(t, checkTapLineSensitive("10時になったら休憩しましょう。"))

	for _, text := range []string{
		"連絡は shiori@example.com までどうぞ",
		"詳しくは https://example.com を見てね",
		"www.example.com にアクセスして",
		"電話は 090-1234-5678 です",
		"番号は 1234567 です",
	} {
		assert.ErrorIs(t, checkTapLineSensitive(text), ErrInvalidChara, text)
	}
}

func TestParseTapLineDrafts(t *testing.T) {
	texts, err := parseTapLineDrafts("```json\n[\"おはようございます。\", \" 今日もいい朝ですね。 \"]\n```")
	assert.NoError(t, err)
	assert.Equal(t, []string{"おはようございます。", "今日もいい朝ですね。"}, texts)

	_, err = parseTapLineDrafts("ごめんなさい、書けませんでした")
	assert.Error(t, err)
}

func TestValidateTapLine(t *testing.T) {
	valid := database.CharaTapLine{ID: "a1b2c3d4e5f6", Text: "おはようございます。", Theme: "morning", When: database.CharaTapLineWhen{Hours: []int{5, 11}}}
	assert.NoError(t, validateTapLine(valid))

	// 日をまたぐ時間帯
	line := valid
	line.When = database.CharaTapLineWhen{Hours: []int{23, 5}}
	assert.NoError(t, validateTapLine(line))

	for name, line := range map[string]database.CharaTapLine{
		"ID が使えない": {ID: "../x", Text: "a"},
		"文が空":      {ID: "a1b2c3d4e5f6", Text: ""},
		"知らないテーマ":  {ID: "a1b2c3d4e5f6", Text: "a", Theme: "birthday-party"},
		"日付の形が違う":  {ID: "a1b2c3d4e5f6", Text: "a", When: database.CharaTapLineWhen{Dates: []string{"12/25"}}},
		"時間帯が1つだけ": {ID: "a1b2c3d4e5f6", Text: "a", When: database.CharaTapLineWhen{Hours: []int{5}}},
		"時間帯が範囲の外": {ID: "a1b2c3d4e5f6", Text: "a", When: database.CharaTapLineWhen{Hours: []int{5, 25}}},
		"曜日が範囲の外":  {ID: "a1b2c3d4e5f6", Text: "a", When: database.CharaTapLineWhen{Weekdays: []int{7}}},
	} {
		assert.ErrorIs(t, validateTapLine(line), ErrInvalidChara, name)
	}
}

func TestTapLineThemes(t *testing.T) {
	// テーマの条件は、保存するときの入力チェックを通る
	for _, theme := range TapLineThemes {
		assert.NoError(t, validateTapLine(database.CharaTapLine{ID: "a1b2c3d4e5f6", Text: "a", Theme: theme.Key, When: theme.When}), theme.Key)
	}
	christmas, ok := findTapLineTheme("christmas")
	assert.True(t, ok)
	assert.Equal(t, []string{"12-24", "12-25"}, christmas.When.Dates)
}
