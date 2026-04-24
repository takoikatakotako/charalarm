package output

type Alarm struct {
	AlarmID        string
	UserID         string
	Type           string
	Target         string
	Enable         bool
	Name           string
	Hour           int
	Minute         int
	TimeDifference float32
	CharaID        string
	CharaName      string
	VoiceFileName  string
	Sunday         bool
	Monday         bool
	Tuesday        bool
	Wednesday      bool
	Thursday       bool
	Friday         bool
	Saturday       bool
}
