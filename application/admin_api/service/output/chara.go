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
	Enable      bool
	CreatedAt   string
	UpdatedAt   string
	Name        string
	Description string
	Profiles    []CharaProfile
	Calls       []CharaCall
	Expressions map[string]CharaExpression
}
