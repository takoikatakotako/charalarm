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
	CharaID     string
	CreatedAt   string
	UpdatedAt   string
	Calls       []CharaCall
	Expressions map[string]CharaExpression
	Settings    CharaSettings
}

// CharaSettings は管理画面で編集する項目。キャラの追加と編集で同じものを使う。
// calls と expressions はリソースのアップロードと一緒に別で編集する。
type CharaSettings struct {
	Enable       bool
	Name         string
	Description  string
	Profiles     []CharaProfile
	DisplayOrder int

	// AppearanceType は "illustration" か "vrm"。vrm のときは VRMFileName を使う。
	AppearanceType string
	VRMFileName    string

	// ConversationType は "none" (アラーム専用)、"voicevox"、"gemini"。
	ConversationType   string
	ConversationPrompt string
	VoicevoxStyleID    int
	GeminiVoice        string
	GeminiVoiceStyle   string
	// 通話の場面のプロンプト。空なら API がサーバの既定を使う。
	CallOpeningPrompt       string
	CallEndingPrompt        string
	CallNoInputEndingPrompt string
}
