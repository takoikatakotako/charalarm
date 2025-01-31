package repository

import (
	"errors"
	"github.com/takoikatakotako/charalarm-worker/message"
	"os"
)

const (
	ResourceBaseURLKey = "RESOURCE_BASE_URL"
	LocalstackEndpoint = "http://localhost:4566"
)

type Environment struct {
	IsLocal bool
}

// GetResourceBaseURL get base url
func (e *Environment) GetResourceBaseURL() (string, error) {
	if e.IsLocal {
		return LocalstackEndpoint, nil
	}

	baseURL := os.Getenv(ResourceBaseURLKey)
	if baseURL == "" {
		return "", errors.New(message.ErrorCanNotFindEnvironmentVariable)
	}
	return baseURL, nil
}
