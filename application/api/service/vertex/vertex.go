package vertex

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// Endpoint は Vertex AI の API のホスト。Gemini (会話・TTS) は global ロケーションで呼ぶ。
const Endpoint = "https://aiplatform.googleapis.com"

const cloudPlatformScope = "https://www.googleapis.com/auth/cloud-platform"

// NewHTTPClient は Vertex AI を呼ぶための認証つき HTTP クライアントを返す。
// credentialConfig (external_account の JSON) を渡すと Workload Identity 連携で認証する (Lambda 用)。
// 空ならアプリケーションのデフォルト認証情報を使う (ローカルでは gcloud auth application-default login)。
// トークンは最初の呼び出しで取得するので、ここでは通信しない。
func NewHTTPClient(ctx context.Context, credentialConfig string) (*http.Client, error) {
	var creds *google.Credentials
	var err error
	if credentialConfig != "" {
		creds, err = google.CredentialsFromJSONWithType(ctx, []byte(credentialConfig), google.ExternalAccount, cloudPlatformScope)
	} else {
		creds, err = google.FindDefaultCredentials(ctx, cloudPlatformScope)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to load google credentials: %w", err)
	}

	httpClient := oauth2.NewClient(ctx, creds.TokenSource)
	httpClient.Timeout = 30 * time.Second
	return httpClient, nil
}
