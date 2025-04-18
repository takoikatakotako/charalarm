package response

type Alarm struct {
	AlarmID string `json:"alarmID"`
	UserID  string `json:"userID"`

	// REMOTE_NOTIFICATION VOIP_NOTIFICATION
	Type           string  `json:"type"`
	Enable         bool    `json:"enable"`
	Name           string  `json:"name"`
	Hour           int     `json:"hour"`
	Minute         int     `json:"minute"`
	TimeDifference float32 `json:"timeDifference"`

	// Chara Info
	CharaID       string `json:"charaID"`
	CharaName     string `json:"charaName"`
	VoiceFileName string `json:"voiceFileName"`

	// Weekday
	Sunday    bool `json:"sunday"`
	Monday    bool `json:"monday"`
	Tuesday   bool `json:"tuesday"`
	Wednesday bool `json:"wednesday"`
	Thursday  bool `json:"thursday"`
	Friday    bool `json:"friday"`
	Saturday  bool `json:"saturday"`
}
