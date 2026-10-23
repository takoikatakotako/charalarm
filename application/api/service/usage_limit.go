package service

import (
	"errors"
	"log/slog"
	"time"

	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// 1日の区切り (日本時間)
var usageLocation = time.FixedZone("Asia/Tokyo", 9*60*60)

// 古い日の使用量を消すまでの時間
const usageRetention = 48 * time.Hour

// UsageLimit は会話と読み上げの1日の上限。費用が膨らみすぎないようにする。
type UsageLimit struct {
	AWS infrastructure.AWS
	// DailyChat は1日に /chat を呼べる回数。0 なら数えない。
	DailyChat int
	// DailyTTSChars は1日に /tts で読み上げられる文字数。0 なら数えない。
	DailyTTSChars int
	// PremiumMultiplier はプレミアムプランの人の上限の倍率。
	PremiumMultiplier int
}

// ErrUsageLimitExceeded は今日の上限を超えた。
var ErrUsageLimitExceeded = errors.New(common.ErrorUsageLimitExceeded)

// Use は今日の使用量を足し、上限を超えたら ErrUsageLimitExceeded を返す。
// 数えられなかったとき (テーブルがないなど) は、電話が止まらないよう通す。
func (l *UsageLimit) Use(user database.User, chat int, ttsChars int, now time.Time) error {
	if l == nil || (l.DailyChat == 0 && l.DailyTTSChars == 0) {
		return nil
	}
	day := now.In(usageLocation).Format("2006-01-02")
	usage, err := l.AWS.AddUsage(user.UserID+"#"+day, chat, ttsChars, now.Add(usageRetention).Unix())
	if err != nil {
		slog.Error("usage count failed", slog.String("error", err.Error()))
		return nil
	}

	multiplier := 1
	if user.PremiumPlan && l.PremiumMultiplier > 0 {
		multiplier = l.PremiumMultiplier
	}
	// このリクエストで増やした方の上限だけを見る (読み上げが上限でも会話は続けられる)
	if (chat > 0 && exceeded(usage.Chat, l.DailyChat*multiplier)) || (ttsChars > 0 && exceeded(usage.TTSChars, l.DailyTTSChars*multiplier)) {
		slog.Warn("usage limit exceeded",
			slog.Int("chat", usage.Chat), slog.Int("tts_chars", usage.TTSChars), slog.Bool("premium", user.PremiumPlan))
		return ErrUsageLimitExceeded
	}
	return nil
}

func exceeded(used int, limit int) bool {
	return limit > 0 && used > limit
}
