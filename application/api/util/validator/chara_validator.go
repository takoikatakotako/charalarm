package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm/api/util/message"
	"github.com/takoikatakotako/charalarm/entity"
)

func ValidateChara(chara entity.Chara) error {
	// CharaID
	if !IsValidUUID(chara.CharaID) {
		return errors.New(message.ErrorInvalidValue + ": CharaID")
	}

	return nil
}
