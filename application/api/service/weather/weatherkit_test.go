package weather

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const forecastJSON = `{
  "forecastDaily": {
    "days": [
      {"forecastStart": "2026-11-03T15:00:00Z", "forecastEnd": "2026-11-04T15:00:00Z",
       "conditionCode": "Rain", "temperatureMax": 17.4, "temperatureMin": 10.6,
       "precipitationChance": 0.7, "precipitationType": "rain"},
      {"forecastStart": "2026-11-04T15:00:00Z", "forecastEnd": "2026-11-05T15:00:00Z",
       "conditionCode": "Clear", "temperatureMax": 19, "temperatureMin": 9,
       "precipitationChance": 0.1, "precipitationType": "clear"}
    ]
  }
}`

func newTestKey(t *testing.T) (*ecdsa.PrivateKey, string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	require.NoError(t, err)
	der, err := x509.MarshalPKCS8PrivateKey(key)
	require.NoError(t, err)
	return key, string(pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: der}))
}

func newTestClient(t *testing.T, handler http.HandlerFunc) (*Client, *ecdsa.PrivateKey) {
	t.Helper()
	key, pemText := newTestKey(t)
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	client, err := NewClient(Config{TeamID: "TEAM", ServiceID: "com.example.weather", KeyID: "KEY", PrivateKey: pemText}, server.Client())
	require.NoError(t, err)
	client.baseURL = server.URL
	return client, key
}

func TestToday(t *testing.T) {
	tokyo, _ := FindRegion("13")
	now := time.Date(2026, 11, 4, 7, 0, 0, 0, time.FixedZone("JST", 9*60*60))

	t.Run("今日の天気を取り、署名した JWT を付ける", func(t *testing.T) {
		var authorization, path string
		client, key := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			authorization = r.Header.Get("Authorization")
			path = r.URL.Path + "?" + r.URL.RawQuery
			_, _ = w.Write([]byte(forecastJSON))
		})
		client.now = func() time.Time { return now }

		forecast, err := client.Today(context.Background(), tokyo)
		require.NoError(t, err)
		assert.Equal(t, "雨", forecast.Condition)
		assert.Equal(t, 17.4, forecast.TemperatureMax)
		assert.Equal(t, "雨", forecast.PrecipitationType)
		assert.Equal(t, "/ja/35.6895/139.6917?dataSets=forecastDaily&timezone=Asia/Tokyo&countryCode=JP", path)

		token := strings.TrimPrefix(authorization, "Bearer ")
		parts := strings.Split(token, ".")
		require.Len(t, parts, 3)
		header := decodeSegment(t, parts[0])
		assert.Equal(t, "ES256", header["alg"])
		assert.Equal(t, "KEY", header["kid"])
		assert.Equal(t, "TEAM.com.example.weather", header["id"])
		claims := decodeSegment(t, parts[1])
		assert.Equal(t, "TEAM", claims["iss"])
		assert.Equal(t, "com.example.weather", claims["sub"])

		signature, err := base64.RawURLEncoding.DecodeString(parts[2])
		require.NoError(t, err)
		require.Len(t, signature, 64)
		digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
		r := new(big.Int).SetBytes(signature[:32])
		s := new(big.Int).SetBytes(signature[32:])
		assert.True(t, ecdsa.Verify(&key.PublicKey, digest[:], r, s))
	})

	t.Run("1時間以内はキャッシュを使い、過ぎたら取り直す", func(t *testing.T) {
		calls := 0
		client, _ := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			calls++
			_, _ = w.Write([]byte(forecastJSON))
		})
		current := now
		client.now = func() time.Time { return current }

		_, err := client.Today(context.Background(), tokyo)
		require.NoError(t, err)
		current = now.Add(59 * time.Minute)
		_, err = client.Today(context.Background(), tokyo)
		require.NoError(t, err)
		assert.Equal(t, 1, calls)

		current = now.Add(61 * time.Minute)
		_, err = client.Today(context.Background(), tokyo)
		require.NoError(t, err)
		assert.Equal(t, 2, calls)
	})

	t.Run("夜中を過ぎたら次の日の予報を使う", func(t *testing.T) {
		client, _ := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			_, _ = w.Write([]byte(forecastJSON))
		})
		client.now = func() time.Time { return now.Add(18 * time.Hour) } // 11/5 1:00
		forecast, err := client.Today(context.Background(), tokyo)
		require.NoError(t, err)
		assert.Equal(t, "晴れ", forecast.Condition)
		assert.Equal(t, "", forecast.PrecipitationType)
	})

	t.Run("エラーのときはキャッシュしない", func(t *testing.T) {
		calls := 0
		client, _ := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
			calls++
			w.WriteHeader(http.StatusUnauthorized)
		})
		client.now = func() time.Time { return now }
		_, err := client.Today(context.Background(), tokyo)
		assert.Error(t, err)
		_, err = client.Today(context.Background(), tokyo)
		assert.Error(t, err)
		assert.Equal(t, 2, calls)
	})
}

func TestNewClientRejectsBadKey(t *testing.T) {
	_, err := NewClient(Config{TeamID: "T", ServiceID: "S", KeyID: "K", PrivateKey: "not a key"}, nil)
	assert.Error(t, err)
}

func TestParsePrivateKeyWithEscapedNewlines(t *testing.T) {
	_, pemText := newTestKey(t)
	_, err := parsePrivateKey(strings.ReplaceAll(pemText, "\n", `\n`))
	assert.NoError(t, err)
}

func TestDescribe(t *testing.T) {
	tokyo, _ := FindRegion("13")
	forecast := Forecast{Region: tokyo, Condition: "雨", TemperatureMax: 17.4, TemperatureMin: 10.6, PrecipitationChance: 0.7, PrecipitationType: "雨"}
	assert.Equal(t, "地域: 東京都\n今日の天気: 雨\n最高気温: 17度\n最低気温: 11度\n降水確率: 70%（雨）", forecast.Describe())

	forecast = Forecast{Region: tokyo, TemperatureMax: 20, TemperatureMin: 12, PrecipitationChance: 0}
	assert.Equal(t, "地域: 東京都\n最高気温: 20度\n最低気温: 12度\n降水確率: 0%", forecast.Describe())
}

func TestFindRegion(t *testing.T) {
	assert.Len(t, regions, 47)
	region, ok := FindRegion("47")
	assert.True(t, ok)
	assert.Equal(t, "沖縄県", region.Name)
	_, ok = FindRegion("48")
	assert.False(t, ok)
	_, ok = FindRegion("")
	assert.False(t, ok)
}

func decodeSegment(t *testing.T, segment string) map[string]any {
	t.Helper()
	data, err := base64.RawURLEncoding.DecodeString(segment)
	require.NoError(t, err)
	var m map[string]any
	require.NoError(t, json.Unmarshal(data, &m))
	return m
}
