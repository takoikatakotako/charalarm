package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm/api/entity/database"
	"github.com/takoikatakotako/charalarm/api/util/message"
)

func ValidateChara(chara database.Chara) error {
	// CharaID
	if !IsValidUUID(chara.CharaID) {
		return errors.New(message.ErrorInvalidValue + ": CharaID")
	}

	return nil
}
