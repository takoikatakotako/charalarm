package environment_variable

import (
	"errors"
	"github.com/takoikatakotako/charalarm-backend/config"
	"github.com/takoikatakotako/charalarm-backend/util/message"
	"os"
)

const (
	ResourceBaseURLKey = "RESOURCE_BASE_URL"
)

type EnvironmentVariableRepository struct {
	IsLocal bool
}

// GetResourceBaseURL get base url
func (e *EnvironmentVariableRepository) GetResourceBaseURL() (string, error) {
	if e.IsLocal {
		return config.LocalstackEndpoint, nil
	}

	baseURL := os.Getenv(ResourceBaseURLKey)
	if baseURL == "" {
		return "", errors.New(message.ErrorCanNotFindEnvironmentVariable)
	}
	return baseURL, nil
}
