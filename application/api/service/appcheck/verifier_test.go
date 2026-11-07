package appcheck

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const testProject = "983259461023"

func newTestVerifier(t *testing.T, key *rsa.PrivateKey, now time.Time) (*Verifier, *int) {
	t.Helper()
	fetches := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		fetches++
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": []map[string]string{{
			"kid": "k1", "kty": "RSA", "alg": "RS256", "use": "sig",
			"n": base64.RawURLEncoding.EncodeToString(key.N.Bytes()),
			"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(key.E)).Bytes()),
		}}})
	}))
	t.Cleanup(server.Close)
	v := NewVerifier(testProject)
	v.JWKSURL = server.URL
	v.Now = func() time.Time { return now }
	return v, &fetches
}

func sign(t *testing.T, key *rsa.PrivateKey, header, payload map[string]any) string {
	t.Helper()
	h, _ := json.Marshal(header)
	p, _ := json.Marshal(payload)
	input := base64.RawURLEncoding.EncodeToString(h) + "." + base64.RawURLEncoding.EncodeToString(p)
	digest := sha256.Sum256([]byte(input))
	sig, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, digest[:])
	require.NoError(t, err)
	return input + "." + base64.RawURLEncoding.EncodeToString(sig)
}

func TestVerify(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	require.NoError(t, err)
	now := time.Date(2026, 11, 8, 7, 0, 0, 0, time.UTC)
	header := map[string]any{"alg": "RS256", "typ": "JWT", "kid": "k1"}
	payload := func() map[string]any {
		return map[string]any{
			"iss": "https://firebaseappcheck.googleapis.com/" + testProject,
			"sub": "1:983259461023:ios:abc",
			"aud": []string{"projects/" + testProject, "projects/charalarm-development"},
			"exp": now.Add(time.Hour).Unix(),
		}
	}

	t.Run("正しいトークンは通り、公開鍵は使い回す", func(t *testing.T) {
		v, fetches := newTestVerifier(t, key, now)
		claims, err := v.Verify(context.Background(), sign(t, key, header, payload()))
		require.NoError(t, err)
		assert.Equal(t, "1:983259461023:ios:abc", claims.Subject)
		_, err = v.Verify(context.Background(), sign(t, key, header, payload()))
		require.NoError(t, err)
		assert.Equal(t, 1, *fetches)
	})

	t.Run("トークンが無い・形が違う", func(t *testing.T) {
		v, _ := newTestVerifier(t, key, now)
		_, err := v.Verify(context.Background(), "")
		assert.ErrorIs(t, err, ErrMissing)
		_, err = v.Verify(context.Background(), "abc.def")
		assert.ErrorIs(t, err, ErrMalformed)
	})

	t.Run("別の鍵で署名したものは通さない", func(t *testing.T) {
		other, err := rsa.GenerateKey(rand.Reader, 2048)
		require.NoError(t, err)
		v, _ := newTestVerifier(t, key, now)
		_, err = v.Verify(context.Background(), sign(t, other, header, payload()))
		assert.ErrorIs(t, err, ErrSignature)
	})

	t.Run("別のプロジェクトのトークンは通さない", func(t *testing.T) {
		v, _ := newTestVerifier(t, key, now)
		p := payload()
		p["aud"] = []string{"projects/951021888899"}
		_, err := v.Verify(context.Background(), sign(t, key, header, p))
		assert.ErrorIs(t, err, ErrClaims)
		p = payload()
		p["iss"] = "https://firebaseappcheck.googleapis.com/951021888899"
		_, err = v.Verify(context.Background(), sign(t, key, header, p))
		assert.ErrorIs(t, err, ErrClaims)
	})

	t.Run("期限切れは通さない", func(t *testing.T) {
		v, _ := newTestVerifier(t, key, now)
		p := payload()
		p["exp"] = now.Add(-2 * time.Minute).Unix()
		_, err := v.Verify(context.Background(), sign(t, key, header, p))
		assert.ErrorIs(t, err, ErrExpired)
	})
}
