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

	// DisplayOrder は一覧の表示順 (昇順)。
	DisplayOrder int `dynamodbav:"displayOrder"`

	// AppearanceType は見た目のタイプ。空なら illustration。AppearanceTypeOf で読む。
	AppearanceType string `dynamodbav:"appearanceType"`
	// VRMFileName は appearanceType が vrm のときの 3D モデルのファイル名。
	VRMFileName string `dynamodbav:"vrmFileName"`

	// ConversationType は会話のタイプ。空なら古い項目から導く。ConversationTypeOf で読む。
	ConversationType   string `dynamodbav:"conversationType"`
	ConversationPrompt string `dynamodbav:"conversationPrompt"`
	VoicevoxStyleID    int    `dynamodbav:"voicevoxStyleID"`
	// ConversationLanguages は会話できる言語 (例: ["ja", "en"])。空なら日本語だけ。ConversationLanguagesOf で読む。
	ConversationLanguages []string `dynamodbav:"conversationLanguages"`

	// VoiceProvider は ConversationType より前の項目 ("voicevox" / "gemini")。
	// ConversationType が空のキャラを読むときだけ使う。
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

// 見た目のタイプ
const (
	// AppearanceTypeIllustration は表情ごとの立ち絵 (expressions の画像)。
	AppearanceTypeIllustration = "illustration"
	// AppearanceTypeVRM は 3D モデル (VRMFileName)。古いアプリ用に立ち絵も持たせる。
	AppearanceTypeVRM = "vrm"
)

// 会話のタイプ
const (
	// ConversationTypeNone はアラーム専用。録音ボイスで電話をかけるだけ。
	ConversationTypeNone = "none"
	// ConversationTypeVoicevox は端末内の VOICEVOX で合成して会話する。
	ConversationTypeVoicevox = "voicevox"
	// ConversationTypeGemini はサーバの /tts (Gemini TTS) で合成して会話する。
	ConversationTypeGemini = "gemini"
)

// 会話の言語
const (
	LanguageJapanese = "ja"
	LanguageEnglish  = "en"
)

// SupportedLanguages は会話に使える言語。
var SupportedLanguages = []string{LanguageJapanese, LanguageEnglish}

// IsSupportedLanguage は会話に使える言語か。
func IsSupportedLanguage(language string) bool {
	for _, l := range SupportedLanguages {
		if l == language {
			return true
		}
	}
	return false
}

// ConversationLanguagesOf は会話できる言語を返す。未設定なら日本語だけ。
func (c Chara) ConversationLanguagesOf() []string {
	if len(c.ConversationLanguages) == 0 {
		return []string{LanguageJapanese}
	}
	return c.ConversationLanguages
}

// ConversationLanguageFor はユーザーが選んだ言語で話せればその言語、話せなければキャラの最初の言語を返す。
func (c Chara) ConversationLanguageFor(preferred string) string {
	languages := c.ConversationLanguagesOf()
	for _, l := range languages {
		if l == preferred {
			return l
		}
	}
	return languages[0]
}

// AppearanceTypeOf は見た目のタイプを返す。未設定なら illustration。
func (c Chara) AppearanceTypeOf() string {
	if c.AppearanceType == "" {
		return AppearanceTypeIllustration
	}
	return c.AppearanceType
}

// ConversationTypeOf は会話のタイプを返す。
// 未設定なら古い項目から導く: 人格プロンプトが空ならアラーム専用、それ以外は voiceProvider (空なら voicevox)。
func (c Chara) ConversationTypeOf() string {
	if c.ConversationType != "" {
		return c.ConversationType
	}
	if c.ConversationPrompt == "" {
		return ConversationTypeNone
	}
	if c.VoiceProvider == "" {
		return ConversationTypeVoicevox
	}
	return c.VoiceProvider
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
