package environment

import "os"

type Environment struct {
	Profile         string
	ResourceBaseURL string
}

func (e *Environment) SetCharalarmAWSProfile(defaultValue string) {
	e.Profile = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_AWS_PROFILE"); exists {
		e.Profile = val
	}
}

func (e *Environment) SetResourceBaseURL(defaultValue string) {
	e.ResourceBaseURL = defaultValue
	if val, exists := os.LookupEnv("CHARALARM_AWS_PROFILE"); exists {
		e.ResourceBaseURL = val
	}
}
