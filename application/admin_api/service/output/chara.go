package output

type CharaProfile struct {
	Title string
	Name  string
	URL   string
}

type CharaCall struct {
	Message       string
	VoiceFileName string
}

type CharaExpression struct {
	ImageFileNames []string
	VoiceFileNames []string
}

type Chara struct {
	CharaID            string
	Enable             bool
	CreatedAt          string
	UpdatedAt          string
	Name               string
	Description        string
	Profiles           []CharaProfile
	Calls              []CharaCall
	Expressions        map[string]CharaExpression
	ConversationPrompt string
	VoicevoxStyleID    int
	Conversation       CharaConversation
}

// CharaConversation は会話の声と通話の場面のプロンプト。空の項目は API がサーバの既定を使う。
type CharaConversation struct {
	VoiceProvider           string
	GeminiVoice             string
	GeminiVoiceStyle        string
	CallOpeningPrompt       string
	CallEndingPrompt        string
	CallNoInputEndingPrompt string
}

// CharaUpdate は管理画面から編集可能なフィールド。
type CharaUpdate struct {
	Enable             bool
	Name               string
	Description        string
	ConversationPrompt string
	VoicevoxStyleID    int
	// Conversation は送られた項目だけ上書きする (nil の項目は今の値のまま)。
	// 管理画面がまだ送らない項目を、保存のたびに空で消さないため。
	Conversation CharaConversationUpdate
}

// CharaConversationUpdate は会話の設定の更新。nil の項目は変えない。
type CharaConversationUpdate struct {
	VoiceProvider           *string
	GeminiVoice             *string
	GeminiVoiceStyle        *string
	CallOpeningPrompt       *string
	CallEndingPrompt        *string
	CallNoInputEndingPrompt *string
}
