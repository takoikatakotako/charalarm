package auth

import (
	"encoding/base64"
	"errors"
	"github.com/takoikatakotako/charalarm-backend/util/validator"
	"strings"
)

func Basic(authorizationHeader string) (string, string, error) {
	array := strings.Split(authorizationHeader, " ")
	if len(array) != 2 {
		return "", "", errors.New("exception")
	}

	// Basic認証ではない
	if array[0] != "Basic" {
		return "", "", errors.New("exception")
	}

	encodedToken := array[1]
	token, err := base64.StdEncoding.DecodeString(encodedToken)
	if err != nil {
		return "", "", err
	}

	tokens := strings.Split(string(token), ":")
	if len(tokens) != 2 {
		return "", "", errors.New("exception")
	}

	userID := tokens[0]
	authToken := tokens[1]

	if validator.IsValidUUID(userID) && validator.IsValidUUID(authToken) {
		return userID, authToken, nil
	}

	// UUID以外の場合
	return "", "", errors.New("exception")
}
