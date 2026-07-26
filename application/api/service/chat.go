package service

import (
	"context"
	"errors"

	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// Chat はずんだもんとの会話応答を生成するサービス。
type Chat struct {
	AWS       infrastructure.AWS
	LLMClient llm.Client
}

// Reply はユーザーを認証したうえで、メッセージ列に対する応答を LLM から生成する。
func (s *Chat) Reply(ctx context.Context, userID string, authToken string, messages []llm.Message) (string, error) {
	// バリデーション
	if !database.IsValidUUID(userID) || !database.IsValidUUID(authToken) {
		return "", errors.New(common.ErrorInvalidValue)
	}

	// ユーザー認証 (LLM の踏み台化を防ぐため、実在ユーザーのみ許可)
	user, err := s.AWS.GetUser(userID)
	if err != nil {
		return "", err
	}
	if user.UserID != userID || user.AuthToken != authToken {
		return "", errors.New(common.ErrorAuthenticationFailure)
	}

	// メッセージが空なら弾く
	if len(messages) == 0 {
		return "", errors.New(common.ErrorInvalidValue)
	}

	return s.LLMClient.Chat(ctx, messages)
}
