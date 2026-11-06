package weather

import (
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"strings"
	"sync"
	"time"
)

const (
	weatherKitBaseURL = "https://weatherkit.apple.com/api/v1/weather"
	// 天気は1時間ごとに取り直す。地域の数 × 24 回 × Lambda の数で、無料枠 (月 50 万回) に収まる
	forecastCacheTTL = time.Hour
	// JWT はこの長さで作り、期限の少し前に作り直す
	tokenLifetime = time.Hour
	tokenRenewal  = 5 * time.Minute
)

// Forecast は地域の今日の天気。
type Forecast struct {
	Region Region
	// Condition は天気 (例: 晴れ時々くもり)。分からなければ空。
	Condition string
	// ConditionCode は WeatherKit の天気のコード (例: Clear, Rain)。アプリはこれで絵と文言を決める。
	ConditionCode string
	// TemperatureMax / TemperatureMin は今日の最高・最低気温 (℃)。
	TemperatureMax float64
	TemperatureMin float64
	// PrecipitationChance は今日の降水確率 (0〜1)。
	PrecipitationChance float64
	// PrecipitationType は降るもの (雨・雪など)。降らない見込みなら空。
	PrecipitationType string
}

// Config は WeatherKit REST API を呼ぶための設定。Apple Developer で作る。
type Config struct {
	TeamID    string
	ServiceID string
	KeyID     string
	// PrivateKey は WeatherKit を有効にした鍵 (.p8 の PEM)。
	PrivateKey string
}

// Enabled は設定がそろっているか。そろっていなければ天気を使わない。
func (c Config) Enabled() bool {
	return c.TeamID != "" && c.ServiceID != "" && c.KeyID != "" && c.PrivateKey != ""
}

// Client は WeatherKit REST API から地域の天気を取る。地域ごとに1時間キャッシュする。
type Client struct {
	config     Config
	privateKey *ecdsa.PrivateKey
	httpClient *http.Client
	baseURL    string
	now        func() time.Time

	mu         sync.Mutex
	token      string
	tokenUntil time.Time
	cache      map[string]cachedForecast
}

type cachedForecast struct {
	forecast  Forecast
	fetchedAt time.Time
}

// NewClient は WeatherKit のクライアントを作る。鍵が読めなければエラー。
func NewClient(config Config, httpClient *http.Client) (*Client, error) {
	privateKey, err := parsePrivateKey(config.PrivateKey)
	if err != nil {
		return nil, err
	}
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 5 * time.Second}
	}
	return &Client{
		config:     config,
		privateKey: privateKey,
		httpClient: httpClient,
		baseURL:    weatherKitBaseURL,
		now:        time.Now,
		cache:      map[string]cachedForecast{},
	}, nil
}

// Today は地域の今日の天気を返す。1時間以内に取ったものがあればそれを返す。
func (c *Client) Today(ctx context.Context, region Region) (Forecast, error) {
	now := c.now()
	c.mu.Lock()
	cached, ok := c.cache[region.Code]
	c.mu.Unlock()
	if ok && now.Sub(cached.fetchedAt) < forecastCacheTTL {
		return cached.forecast, nil
	}

	forecast, err := c.fetch(ctx, region, now)
	if err != nil {
		return Forecast{}, err
	}
	c.mu.Lock()
	c.cache[region.Code] = cachedForecast{forecast: forecast, fetchedAt: now}
	c.mu.Unlock()
	return forecast, nil
}

func (c *Client) fetch(ctx context.Context, region Region, now time.Time) (Forecast, error) {
	token, err := c.authToken(now)
	if err != nil {
		return Forecast{}, err
	}
	url := fmt.Sprintf("%s/ja/%.4f/%.4f?dataSets=forecastDaily&timezone=Asia/Tokyo&countryCode=JP",
		c.baseURL, region.Latitude, region.Longitude)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return Forecast{}, err
	}
	req.Header.Set("Authorization", "Bearer "+token)

	res, err := c.httpClient.Do(req)
	if err != nil {
		return Forecast{}, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, res.Body)
		return Forecast{}, fmt.Errorf("weatherkit: status %d", res.StatusCode)
	}

	var body weatherResponse
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		return Forecast{}, fmt.Errorf("weatherkit: decode: %w", err)
	}
	day, ok := body.today(now)
	if !ok {
		return Forecast{}, errors.New("weatherkit: no daily forecast")
	}
	return Forecast{
		Region:              region,
		Condition:           conditionNames[day.ConditionCode],
		ConditionCode:       day.ConditionCode,
		TemperatureMax:      day.TemperatureMax,
		TemperatureMin:      day.TemperatureMin,
		PrecipitationChance: day.PrecipitationChance,
		PrecipitationType:   precipitationNames[day.PrecipitationType],
	}, nil
}

type weatherResponse struct {
	ForecastDaily *struct {
		Days []dayForecast `json:"days"`
	} `json:"forecastDaily"`
}

type dayForecast struct {
	ForecastStart       time.Time `json:"forecastStart"`
	ForecastEnd         time.Time `json:"forecastEnd"`
	ConditionCode       string    `json:"conditionCode"`
	TemperatureMax      float64   `json:"temperatureMax"`
	TemperatureMin      float64   `json:"temperatureMin"`
	PrecipitationChance float64   `json:"precipitationChance"`
	PrecipitationType   string    `json:"precipitationType"`
}

// today は今の時刻を含む日の予報。見つからなければ最初の日。
func (r weatherResponse) today(now time.Time) (dayForecast, bool) {
	if r.ForecastDaily == nil || len(r.ForecastDaily.Days) == 0 {
		return dayForecast{}, false
	}
	for _, day := range r.ForecastDaily.Days {
		if !now.Before(day.ForecastStart) && now.Before(day.ForecastEnd) {
			return day, true
		}
	}
	return r.ForecastDaily.Days[0], true
}

// authToken は WeatherKit に渡す JWT (ES256)。期限が近づくまで使い回す。
func (c *Client) authToken(now time.Time) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.token != "" && now.Before(c.tokenUntil.Add(-tokenRenewal)) {
		return c.token, nil
	}
	token, err := signToken(c.config, c.privateKey, now)
	if err != nil {
		return "", err
	}
	c.token = token
	c.tokenUntil = now.Add(tokenLifetime)
	return token, nil
}

func signToken(config Config, privateKey *ecdsa.PrivateKey, now time.Time) (string, error) {
	header, err := json.Marshal(map[string]string{
		"alg": "ES256",
		"kid": config.KeyID,
		"id":  config.TeamID + "." + config.ServiceID,
	})
	if err != nil {
		return "", err
	}
	claims, err := json.Marshal(map[string]any{
		"iss": config.TeamID,
		"sub": config.ServiceID,
		"iat": now.Unix(),
		"exp": now.Add(tokenLifetime).Unix(),
	})
	if err != nil {
		return "", err
	}
	signingInput := base64.RawURLEncoding.EncodeToString(header) + "." + base64.RawURLEncoding.EncodeToString(claims)
	digest := sha256.Sum256([]byte(signingInput))
	r, s, err := ecdsa.Sign(rand.Reader, privateKey, digest[:])
	if err != nil {
		return "", err
	}
	// JWS の ES256 は r と s を 32 バイトずつ並べる
	signature := make([]byte, 64)
	r.FillBytes(signature[:32])
	s.FillBytes(signature[32:])
	return signingInput + "." + base64.RawURLEncoding.EncodeToString(signature), nil
}

func parsePrivateKey(pemText string) (*ecdsa.PrivateKey, error) {
	// 環境変数で改行を \n と書いたときも読めるようにする
	pemText = strings.ReplaceAll(pemText, `\n`, "\n")
	block, _ := pem.Decode([]byte(pemText))
	if block == nil {
		return nil, errors.New("weatherkit: private key is not PEM")
	}
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("weatherkit: parse private key: %w", err)
	}
	ecKey, ok := key.(*ecdsa.PrivateKey)
	if !ok {
		return nil, errors.New("weatherkit: private key is not ECDSA")
	}
	return ecKey, nil
}

// Describe は LLM に渡す天気の文。分からない項目は書かない。
func (f Forecast) Describe() string {
	lines := []string{"地域: " + f.Region.Name}
	if f.Condition != "" {
		lines = append(lines, "今日の天気: "+f.Condition)
	}
	lines = append(lines, fmt.Sprintf("最高気温: %d度", int(math.Round(f.TemperatureMax))))
	lines = append(lines, fmt.Sprintf("最低気温: %d度", int(math.Round(f.TemperatureMin))))
	chance := fmt.Sprintf("降水確率: %d%%", int(math.Round(f.PrecipitationChance*100)))
	if f.PrecipitationType != "" {
		chance += "（" + f.PrecipitationType + "）"
	}
	lines = append(lines, chance)
	return strings.Join(lines, "\n")
}

// conditionNames は WeatherKit の conditionCode を日本語にする。知らないコードは天気を書かない。
var conditionNames = map[string]string{
	"Clear":                  "晴れ",
	"MostlyClear":            "晴れ",
	"PartlyCloudy":           "晴れ時々くもり",
	"MostlyCloudy":           "くもり",
	"Cloudy":                 "くもり",
	"Foggy":                  "霧",
	"Haze":                   "もや",
	"Smoky":                  "煙霧",
	"BlowingDust":            "砂ぼこり",
	"Breezy":                 "やや風が強い",
	"Windy":                  "風が強い",
	"Drizzle":                "霧雨",
	"Rain":                   "雨",
	"HeavyRain":              "大雨",
	"SunShowers":             "晴れ時々にわか雨",
	"IsolatedThunderstorms":  "ところにより雷雨",
	"ScatteredThunderstorms": "ところにより雷雨",
	"Thunderstorms":          "雷雨",
	"StrongStorms":           "激しい雷雨",
	"Frigid":                 "厳しい寒さ",
	"Hot":                    "厳しい暑さ",
	"Hail":                   "ひょう",
	"Flurries":               "にわか雪",
	"SunFlurries":            "晴れ時々にわか雪",
	"Sleet":                  "みぞれ",
	"Snow":                   "雪",
	"HeavySnow":              "大雪",
	"WintryMix":              "雪まじりの雨",
	"BlowingSnow":            "地吹雪",
	"Blizzard":               "吹雪",
	"FreezingDrizzle":        "着氷性の霧雨",
	"FreezingRain":           "着氷性の雨",
	"TropicalStorm":          "熱帯低気圧による荒天",
	"Hurricane":              "台風",
}

// precipitationNames は WeatherKit の precipitationType を日本語にする。"clear" (降らない) は書かない。
var precipitationNames = map[string]string{
	"precipitation": "雨や雪",
	"rain":          "雨",
	"snow":          "雪",
	"sleet":         "みぞれ",
	"hail":          "ひょう",
	"mixed":         "雨や雪",
}
