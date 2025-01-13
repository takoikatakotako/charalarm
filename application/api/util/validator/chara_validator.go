package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"github.com/takoikatakotako/charalarm-backend/util/message"
)

func ValidateChara(chara database.Chara) error {
	// CharaID
	if !IsValidUUID(chara.CharaID) {
		return errors.New(message.ErrorInvalidValue + ": CharaID")
	}

	return nil
}
