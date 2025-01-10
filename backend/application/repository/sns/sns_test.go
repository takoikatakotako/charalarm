package sns

import (
	"fmt"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/entity/sns"
	"strings"
	"testing"
)

func TestCreateVoipPlatformEndpoint(t *testing.T) {
	repository := SNSRepository{IsLocal: true}

	token := uuid.New().String()
	endpointArn, err := repository.CreateIOSVoipPushPlatformEndpoint(token)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	assert.NotEqual(t, len(endpointArn), 0)
}

// エンドポイントを重複して作るとエラーになる
func TestDuplicateVoipPlatformEndpoint(t *testing.T) {
	repository := SNSRepository{IsLocal: true}

	token := uuid.New().String()
	_, err := repository.CreateIOSVoipPushPlatformEndpoint(token)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	_, err = repository.CreateIOSVoipPushPlatformEndpoint(token)
	message := fmt.Sprint(err)
	assert.Equal(t, strings.Contains(message, "DuplicateEndpoint"), true)
}

// エンドポイントを作成してPublishにする
func TestPublishPlatformApplication(t *testing.T) {
	repository := SNSRepository{IsLocal: true}

	// endpointを作成
	token := uuid.New().String()
	endpointArn, err := repository.CreateIOSVoipPushPlatformEndpoint(token)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// 詰め替える
	iOSVoIPPushSNSMessage := sns.IOSVoIPPushSNSMessage{}
	iOSVoIPPushSNSMessage.CharaName = "キャラ名"
	iOSVoIPPushSNSMessage.VoiceFileURL = "ファイルPath"

	err = repository.PublishPlatformApplication(endpointArn, iOSVoIPPushSNSMessage)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}
