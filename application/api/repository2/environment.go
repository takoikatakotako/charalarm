package repository2

import (
	"errors"
	"github.com/takoikatakotako/charalarm-api/util/message"
	"os"
)

const (
	ResourceBaseURLKey = "RESOURCE_BASE_URL"
)

type Environment struct {
	IsLocal bool
}

// GetResourceBaseURL get base url
func (e *Environment) GetResourceBaseURL() (string, error) {
	if e.IsLocal {
		return "http://localhost:4566", nil
	}

	baseURL := os.Getenv(ResourceBaseURLKey)
	if baseURL == "" {
		return "", errors.New(message.ErrorCanNotFindEnvironmentVariable)
	}
	return baseURL, nil
}
