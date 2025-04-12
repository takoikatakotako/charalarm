package validator

import (
	"errors"
	"github.com/takoikatakotako/charalarm/common"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

func ValidateChara(chara database.Chara) error {
	// CharaID
	if !IsValidUUID(chara.CharaID) {
		return errors.New(common.ErrorInvalidValue + ": CharaID")
	}

	return nil
}
