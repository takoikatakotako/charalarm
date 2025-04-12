package output

type Alarm struct {
	AlarmID string
	UserID  string

	// REMOTE_NOTIFICATION VOIP_NOTIFICATION
	Type           string
	Enable         bool
	Name           string
	Hour           int
	Minute         int
	TimeDifference float32

	// Chara Info
	CharaID       string
	CharaName     string
	VoiceFileName string

	// Weekday
	Sunday    bool
	Monday    bool
	Tuesday   bool
	Wednesday bool
	Thursday  bool
	Friday    bool
	Saturday  bool
}
