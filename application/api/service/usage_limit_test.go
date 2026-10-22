package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestExceeded(t *testing.T) {
	assert.False(t, exceeded(60, 60), "ちょうど上限までは使える")
	assert.True(t, exceeded(61, 60), "上限を超えたら止める")
	assert.False(t, exceeded(1000, 0), "上限 0 は数えない")
}
