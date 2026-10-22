package database

const (
	UsageTableName = "usage-table"
	// UsageTableUsageKey は "<userID>#<日付 (日本時間, 2006-01-02)>"
	UsageTableUsageKey  = "usageKey"
	UsageTableChat      = "chat"
	UsageTableTTSChars  = "ttsChars"
	UsageTableExpiresAt = "expiresAt"
)

// Usage はユーザーの1日の使用量。会話と読み上げの費用が膨らみすぎないよう数える。
// 古い日の分は expiresAt (TTL) で消える。
type Usage struct {
	UsageKey string `dynamodbav:"usageKey"`
	// Chat は /chat を呼んだ回数
	Chat int `dynamodbav:"chat"`
	// TTSChars は /tts で読み上げた文字数
	TTSChars  int   `dynamodbav:"ttsChars"`
	ExpiresAt int64 `dynamodbav:"expiresAt"`
}
