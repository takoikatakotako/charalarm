package output

// Weather は地域の今日の天気。
type Weather struct {
	// Region は都道府県コード ("01"〜"47")。
	Region string `json:"region"`
	// ConditionCode は WeatherKit の天気のコード (例: Clear, Rain)。分からなければ空。
	ConditionCode string `json:"conditionCode"`
	// TemperatureMax / TemperatureMin は今日の最高・最低気温 (℃)。
	TemperatureMax float64 `json:"temperatureMax"`
	TemperatureMin float64 `json:"temperatureMin"`
	// PrecipitationChance は今日の降水確率 (0〜1)。
	PrecipitationChance float64 `json:"precipitationChance"`
}
