// Package trendnews は X の話題のニュースを取り、子ども（9+）が朝に聞いてよいものを選んで配る。
// batch が 1 日に数回まとめて作り、アプリ（ホームの「話題」とモーニングコール）は配った JSON を使い回す。
package trendnews

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

const xAPIBaseURL = "https://api.x.com"

// Story は X のニュース（X の投稿をまとめたもの）。
type Story struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Hook     string `json:"hook"`
	Summary  string `json:"summary"`
	Category string `json:"category"`
	// UpdatedAt は X がニュースを更新した時刻 (RFC 3339)。
	UpdatedAt string `json:"updated_at"`
}

// XClient は X API v2 の News 検索を呼ぶ。
type XClient struct {
	BearerToken string
	HTTPClient  *http.Client
	BaseURL     string
}

// NewXClient は X API のクライアントを作る。
func NewXClient(bearerToken string) *XClient {
	return &XClient{
		BearerToken: bearerToken,
		HTTPClient:  &http.Client{Timeout: 20 * time.Second},
		BaseURL:     xAPIBaseURL,
	}
}

// Search は query に合うニュースを、maxAgeHours 時間以内に更新されたものから maxResults 件まで返す。
func (c *XClient) Search(ctx context.Context, query string, maxResults int, maxAgeHours int) ([]Story, error) {
	params := url.Values{}
	params.Set("query", query)
	params.Set("max_results", strconv.Itoa(maxResults))
	params.Set("max_age_hours", strconv.Itoa(maxAgeHours))
	params.Set("news.fields", "category,name,hook,summary,updated_at")
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.BaseURL+"/2/news/search?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.BearerToken)
	// 言語の指定は Queries の lang:ja で行う (X は Accept-Language を見ていない)。ヘッダは念のため残す
	req.Header.Set("Accept-Language", "ja")

	res, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, res.Body)
		return nil, fmt.Errorf("x news search: status %d", res.StatusCode)
	}

	var body struct {
		Data []Story `json:"data"`
	}
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		return nil, fmt.Errorf("x news search: decode: %w", err)
	}
	return body.Data, nil
}
