package service

import (
	"errors"
	"log/slog"

	"github.com/takoikatakotako/charalarm/common"
)

// invalidValue は値がおかしいときのエラーを返し、どこがおかしかったかをログに残す。
// 端末からは 400 しか見えないので、デバッグできるよう理由だけ残す。
// 個人情報をサーバに残さないため、attrs には会話の中身を入れず、長さや件数だけにする。
func invalidValue(reason string, attrs ...any) error {
	slog.Warn("invalid value", append([]any{slog.String("reason", reason)}, attrs...)...)
	return errors.New(common.ErrorInvalidValue)
}
