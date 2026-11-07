// Package appcheck は Firebase App Check のトークンを確かめる。
// アプリは App Attest で本物のアプリ・端末だと Firebase に証明し、Firebase が出したトークンを API に付けてくる。
// サーバは Firebase の公開鍵 (JWKS) で署名と中身を確かめるだけで、端末ごとの情報は何も保存しない。
package appcheck

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"slices"
	"strings"
	"sync"
	"time"
)

const (
	jwksURL = "https://firebaseappcheck.googleapis.com/v1/jwks"
	// 公開鍵は Firebase の推奨どおり 6 時間まで使い回す
	jwksCacheTTL = 6 * time.Hour
	issuerPrefix = "https://firebaseappcheck.googleapis.com/"
	// 端末の時計のずれを少しだけ許す
	clockSkew = time.Minute
)

// トークンを確かめた結果。ログの集計に使うので、理由ごとに分ける。
var (
	ErrMissing   = errors.New("app check: token missing")
	ErrMalformed = errors.New("app check: token malformed")
	ErrSignature = errors.New("app check: bad signature")
	ErrClaims    = errors.New("app check: bad claims")
	ErrExpired   = errors.New("app check: token expired")
)

// Verifier は Firebase App Check のトークンを確かめる。
type Verifier struct {
	// ProjectNumber は Firebase のプロジェクト番号 (GoogleService-Info.plist の GCM_SENDER_ID)。
	ProjectNumber string
	HTTPClient    *http.Client
	JWKSURL       string
	// Now は今の時刻 (テスト用)。nil なら time.Now。
	Now func() time.Time

	mu        sync.Mutex
	keys      map[string]*rsa.PublicKey
	fetchedAt time.Time
}

// NewVerifier はプロジェクト番号の App Check のトークンを確かめる Verifier を作る。
func NewVerifier(projectNumber string) *Verifier {
	return &Verifier{
		ProjectNumber: projectNumber,
		HTTPClient:    &http.Client{Timeout: 5 * time.Second},
		JWKSURL:       jwksURL,
	}
}

// Claims はトークンの中身のうち使うもの。
type Claims struct {
	// Subject はトークンを取ったアプリの Firebase の App ID。
	Subject string
}

// Verify はトークンの署名・発行元・宛先・期限を確かめる。
func (v *Verifier) Verify(ctx context.Context, token string) (Claims, error) {
	if token == "" {
		return Claims{}, ErrMissing
	}
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return Claims{}, ErrMalformed
	}

	var header struct {
		Alg string `json:"alg"`
		Kid string `json:"kid"`
		Typ string `json:"typ"`
	}
	if err := decodeSegment(parts[0], &header); err != nil {
		return Claims{}, ErrMalformed
	}
	if header.Alg != "RS256" || header.Typ != "JWT" || header.Kid == "" {
		return Claims{}, ErrMalformed
	}

	key, err := v.key(ctx, header.Kid)
	if err != nil {
		return Claims{}, err
	}
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return Claims{}, ErrMalformed
	}
	digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if err := rsa.VerifyPKCS1v15(key, crypto.SHA256, digest[:], signature); err != nil {
		return Claims{}, ErrSignature
	}

	var payload struct {
		Iss string          `json:"iss"`
		Sub string          `json:"sub"`
		Aud json.RawMessage `json:"aud"`
		Exp int64           `json:"exp"`
	}
	if err := decodeSegment(parts[1], &payload); err != nil {
		return Claims{}, ErrMalformed
	}
	if payload.Iss != issuerPrefix+v.ProjectNumber || payload.Sub == "" {
		return Claims{}, ErrClaims
	}
	if !slices.Contains(audiences(payload.Aud), "projects/"+v.ProjectNumber) {
		return Claims{}, ErrClaims
	}
	if v.now().After(time.Unix(payload.Exp, 0).Add(clockSkew)) {
		return Claims{}, ErrExpired
	}
	return Claims{Subject: payload.Sub}, nil
}

func (v *Verifier) now() time.Time {
	if v.Now != nil {
		return v.Now()
	}
	return time.Now()
}

// key は kid の公開鍵を返す。知らない kid なら (鍵が入れ替わったかもしれないので) 取り直す。
func (v *Verifier) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	fresh := v.now().Sub(v.fetchedAt) < jwksCacheTTL
	if key, ok := v.keys[kid]; ok && fresh {
		return key, nil
	}
	keys, err := v.fetchKeys(ctx)
	if err != nil {
		// 取れなければ、古い鍵があればそれを使う
		if key, ok := v.keys[kid]; ok {
			return key, nil
		}
		return nil, err
	}
	v.keys = keys
	v.fetchedAt = v.now()
	key, ok := keys[kid]
	if !ok {
		return nil, ErrSignature
	}
	return key, nil
}

func (v *Verifier) fetchKeys(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, v.JWKSURL, nil)
	if err != nil {
		return nil, err
	}
	res, err := v.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("app check: jwks: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, res.Body)
		return nil, fmt.Errorf("app check: jwks: status %d", res.StatusCode)
	}
	var body struct {
		Keys []struct {
			Kid string `json:"kid"`
			Kty string `json:"kty"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		return nil, fmt.Errorf("app check: jwks: decode: %w", err)
	}
	keys := map[string]*rsa.PublicKey{}
	for _, k := range body.Keys {
		if k.Kty != "RSA" {
			continue
		}
		n, errN := base64.RawURLEncoding.DecodeString(k.N)
		e, errE := base64.RawURLEncoding.DecodeString(k.E)
		if errN != nil || errE != nil {
			continue
		}
		keys[k.Kid] = &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: int(new(big.Int).SetBytes(e).Int64())}
	}
	if len(keys) == 0 {
		return nil, errors.New("app check: jwks: no keys")
	}
	return keys, nil
}

func decodeSegment(segment string, v any) error {
	data, err := base64.RawURLEncoding.DecodeString(segment)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

// audiences は aud (文字列か文字列の配列) を配列にする。
func audiences(raw json.RawMessage) []string {
	var list []string
	if json.Unmarshal(raw, &list) == nil {
		return list
	}
	var one string
	if json.Unmarshal(raw, &one) == nil {
		return []string{one}
	}
	return nil
}
