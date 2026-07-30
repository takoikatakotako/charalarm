package service

import (
	"sort"

	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

type News struct {
	AWS infrastructure.AWS
}

// ListNews お知らせを新しい順で返す。
func (s *News) ListNews() ([]output.News, error) {
	newsList, err := s.AWS.ScanNews()
	if err != nil {
		return nil, err
	}

	out := make([]output.News, 0, len(newsList))
	for _, n := range newsList {
		out = append(out, output.News{
			NewsID:       n.NewsID,
			Title:        n.Title,
			Body:         n.Body,
			RegisteredAt: n.RegisteredAt,
		})
	}

	// registeredAt (RFC3339) は文字列比較で新しい順にソートできる
	sort.Slice(out, func(i, j int) bool {
		return out[i].RegisteredAt > out[j].RegisteredAt
	})

	return out, nil
}
