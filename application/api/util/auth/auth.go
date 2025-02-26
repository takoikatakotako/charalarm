package auth

import (
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/takoikatakotako/charalarm-api/util/validator"
	"strings"
)

func Basic(authorizationHeader string) (string, string, error) {
	fmt.Printf("authHeader: %s\n", authorizationHeader)
	array := strings.Split(authorizationHeader, " ")
	if len(array) != 2 {
		return "", "", errors.New("auth error1")
	}

	// Basic認証ではない
	if array[0] != "Basic" {
		return "", "", errors.New("auth error2")
	}

	encodedToken := array[1]
	token, err := base64.StdEncoding.DecodeString(encodedToken)
	if err != nil {
		return "", "", err
	}

	tokens := strings.Split(string(token), ":")
	if len(tokens) != 2 {
		return "", "", errors.New("auth error3")
	}

	userID := tokens[0]
	authToken := tokens[1]

	if validator.IsValidUUID(userID) && validator.IsValidUUID(authToken) {
		return userID, authToken, nil
	}

	// UUID以外の場合
	return "", "", errors.New("auth error4")
}
