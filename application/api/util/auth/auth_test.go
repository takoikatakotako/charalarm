package auth

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestBasicAuth(t *testing.T) {
	// $(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
	// MjBmMGMxY2QtOWMyYS00MTFhLTg3OGMtOWJkMGJiMTVkYzM1OjAzOGE1ZTI4LTE1Y2UtNDZiNC04ZjQ2LTQ5MzQyMDJmYWE4NQ==

	// デコードできる
	userID, authToken, err := Basic("Basic MjBmMGMxY2QtOWMyYS00MTFhLTg3OGMtOWJkMGJiMTVkYzM1OjAzOGE1ZTI4LTE1Y2UtNDZiNC04ZjQ2LTQ5MzQyMDJmYWE4NQ==")
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.Equal(t, "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35", userID)
	assert.Equal(t, "038a5e28-15ce-46b4-8f46-4934202faa85", authToken)

	// Basic以外の場合
	userID, authToken, err = Basic("Bearer MjBmMGMxY2QtOWMyYS00MTFhLTg3OGMtOWJkMGJiMTVkYzM1OjAzOGE1ZTI4LTE1Y2UtNDZiNC04ZjQ2LTQ5MzQyMDJmYWE4NQ==")
	assert.Error(t, err)

	// スペースが複数の場合
	userID, authToken, err = Basic("Basic Basic Basic")
	assert.Error(t, err)
}
