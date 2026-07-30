package service

import (
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type News struct {
	AWS infrastructure.AWS
}

// ScanNews お知らせを新しい順で返す。
func (s *News) ScanNews() ([]output.News, error) {
	newsList, err := s.AWS.ScanNews()
	if err != nil {
		return nil, err
	}

	out := make([]output.News, 0, len(newsList))
	for _, n := range newsList {
		out = append(out, toNewsOutput(n))
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].RegisteredAt > out[j].RegisteredAt
	})
	return out, nil
}

// CreateNews お知らせを作成して即公開する。
func (s *News) CreateNews(title string, body string) (output.News, error) {
	news := database.News{
		NewsID:       uuid.New().String(),
		Title:        title,
		Body:         body,
		RegisteredAt: time.Now().Format(time.RFC3339),
	}
	if err := s.AWS.InsertNews(news); err != nil {
		return output.News{}, err
	}
	return toNewsOutput(news), nil
}

// DeleteNews お知らせを削除する。
func (s *News) DeleteNews(newsID string) error {
	return s.AWS.DeleteNews(newsID)
}

func toNewsOutput(n database.News) output.News {
	return output.News{
		NewsID:       n.NewsID,
		Title:        n.Title,
		Body:         n.Body,
		RegisteredAt: n.RegisteredAt,
	}
}
