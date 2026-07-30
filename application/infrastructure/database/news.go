package database

import (
	"errors"

	"github.com/takoikatakotako/charalarm/common"
)

const (
	NewsTableName   = "news-table"
	NewsTableNewsID = "newsID"
)

// News はアプリ内お知らせ (タイトル + 本文)。
type News struct {
	NewsID       string `dynamodbav:"newsID"`
	Title        string `dynamodbav:"title"`
	Body         string `dynamodbav:"body"`
	RegisteredAt string `dynamodbav:"registeredAt"` // RFC3339
}

func ValidateNews(news News) error {
	if !IsValidUUID(news.NewsID) {
		return errors.New(common.ErrorInvalidValue + ": NewsID")
	}
	if news.Title == "" {
		return errors.New(common.ErrorInvalidValue + ": Title")
	}
	if news.Body == "" {
		return errors.New(common.ErrorInvalidValue + ": Body")
	}
	return nil
}
