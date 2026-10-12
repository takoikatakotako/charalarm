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

	// 会話キャラ用。ConversationPrompt が空でないキャラは音声会話に対応する。
	ConversationPrompt string `dynamodbav:"conversationPrompt"`
	VoicevoxStyleID    int    `dynamodbav:"voicevoxStyleID"`

	// VoiceProvider は会話の声の出し方 ("voicevox": 端末内 / "gemini": サーバの /tts)。空なら voicevox。
	VoiceProvider string `dynamodbav:"voiceProvider"`
	// GeminiVoice は Gemini TTS の声 (例: ja-jp-advisor-5、複製した声なら voice_...)。空ならサーバの既定。
	GeminiVoice string `dynamodbav:"geminiVoice"`
	// GeminiVoiceStyle は Gemini TTS の話し方の指示 (省略可)。
	GeminiVoiceStyle string `dynamodbav:"geminiVoiceStyle"`

	// 通話の場面のプロンプト。空ならサーバの既定を使う。
	CallOpeningPrompt       string `dynamodbav:"callOpeningPrompt"`
	CallEndingPrompt        string `dynamodbav:"callEndingPrompt"`
	CallNoInputEndingPrompt string `dynamodbav:"callNoInputEndingPrompt"`
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
