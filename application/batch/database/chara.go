package database

const (
	CharaTableName    = "chara-table"
	CharaTableCharaID = "charaID"
)

type Chara struct {
	CharaID     string                     `dynamodbav:"charaID"`
	Enable      bool                       `dynamodbav:"enable"`
	CreatedAt   string                     `dynamodbav:"created_at"`
	UpdatedAd   string                     `dynamodbav:"updated_at"`
	Name        string                     `dynamodbav:"name"`
	Description string                     `dynamodbav:"description"`
	Profiles    []CharaProfile             `dynamodbav:"profiles"`
	Expressions map[string]CharaExpression `dynamodbav:"expressions"`
	Calls       []CharaCall                `dynamodbav:"calls"`
}

type CharaProfile struct {
	Title string `dynamodbav:"title"`
	Name  string `dynamodbav:"name"`
	URL   string `dynamodbav:"url"`
}

type CharaResource struct {
	FileName string `dynamodbav:"fileName"`
}

type CharaExpression struct {
	ImageFileNames []string `dynamodbav:"imageFileNames"`
	VoiceFileNames []string `dynamodbav:"voiceFileNames"`
}

type CharaCall struct {
	Message       string `dynamodbav:"message"`
	VoiceFileName string `dynamodbav:"voiceFileName"`
}
