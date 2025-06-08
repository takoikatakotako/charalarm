package response

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
