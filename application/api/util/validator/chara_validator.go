package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm/api/util/message"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func ValidateChara(chara database.Chara) error {
	// CharaID
	if !IsValidUUID(chara.CharaID) {
		return errors.New(message.ErrorInvalidValue + ": CharaID")
	}

	return nil
}
