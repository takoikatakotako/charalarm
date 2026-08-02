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
}

// CharaUpdate は管理画面から編集可能なフィールド。
type CharaUpdate struct {
	Enable             bool
	Name               string
	Description        string
	ConversationPrompt string
	VoicevoxStyleID    int
}
