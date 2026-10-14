package output

type Chara struct {
	CharaID     string                     `json:"charaID"`
	Enable      bool                       `json:"enable"`
	Name        string                     `json:"name"`
	CreatedAt   string                     `json:"createdAt"`
	UpdatedAt   string                     `json:"updatedAt"`
	Description string                     `json:"description"`
	Profiles    []CharaProfile             `json:"profiles"`
	Resources   []CharaResource            `json:"resources"`
	Expression  map[string]CharaExpression `json:"expressions"`
	Calls       []CharaCall                `json:"calls"`
	// Appearance は既定の見た目 (古いアプリ用)。Appearances は選べる見た目で、先頭が既定。
	Appearance  CharaAppearance   `json:"appearance"`
	Appearances []CharaAppearance `json:"appearances"`
	// Conversation は会話に対応するキャラだけが持つ。
	Conversation *CharaConversation `json:"conversation,omitempty"`
}

// CharaAppearance は見た目。Type が vrm のときは ModelFileURL に 3D モデルがある。
// 古いアプリは見ないので、vrm のキャラも expressions に立ち絵を持たせる。
type CharaAppearance struct {
	// Type は "illustration" か "vrm"。
	Type         string `json:"type"`
	ModelFileURL string `json:"modelFileURL,omitempty"`
}

// CharaConversation は会話の設定。キャラの人格プロンプトと Gemini の声はサーバだけが持つ。
type CharaConversation struct {
	// VoiceProvider は "voicevox" (端末内で合成) か "gemini" (/tts で合成)。
	VoiceProvider       string `json:"voiceProvider"`
	VoicevoxStyleID     int    `json:"voicevoxStyleID"`
	OpeningPrompt       string `json:"openingPrompt"`
	EndingPrompt        string `json:"endingPrompt"`
	NoInputEndingPrompt string `json:"noInputEndingPrompt"`
}

type CharaProfile struct {
	Title string `json:"title"`
	Name  string `json:"name"`
	URL   string `json:"url"`
}

type CharaResource struct {
	FileURL string `json:"fileURL"`
}

type CharaExpression struct {
	ImageFileURLs []string `json:"imageFileURLs"`
	VoiceFileURLs []string `json:"voiceFileURLs"`
}

type CharaCall struct {
	Message       string `json:"message"`
	VoiceFileName string `json:"voiceFileName"`
	VoiceFileURL  string `json:"voiceFileURL"`
}
