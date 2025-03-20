package repository

type Environment2 struct {
	ResourceBaseURL string
}

func (e *Environment2) SetResourceBaseURL(url string) {
	e.ResourceBaseURL = url
}
