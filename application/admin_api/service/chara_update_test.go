package service

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// 管理画面が送らない項目 (nil) は今の値のまま残ること。
func TestSetIfPresent(t *testing.T) {
	value := "gemini"
	empty := ""

	dst := "voicevox"
	setIfPresent(&dst, nil)
	assert.Equal(t, "voicevox", dst)

	setIfPresent(&dst, &value)
	assert.Equal(t, "gemini", dst)

	// 空文字が送られたら空にする (サーバの既定に戻す)
	setIfPresent(&dst, &empty)
	assert.Equal(t, "", dst)
}
