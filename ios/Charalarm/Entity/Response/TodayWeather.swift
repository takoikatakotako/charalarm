import Foundation

/// 地域の今日の天気（/weather）。トップに出す
struct TodayWeather: Decodable, Equatable {
    /// 都道府県コード ("01"〜"47")
    let region: String
    /// WeatherKit の天気のコード (例: Clear, Rain)。分からなければ空
    let conditionCode: String
    /// 今日の最高・最低気温 (℃)
    let temperatureMax: Double
    let temperatureMin: Double
    /// 今日の降水確率 (0〜1)
    let precipitationChance: Double

    /// 天気の絵 (SF Symbols)
    var symbolName: String {
        Self.symbolNames[conditionCode] ?? "cloud.sun.fill"
    }

    /// 降水確率が高い日だけ出す（%）
    var notablePrecipitationPercent: Int? {
        let percent = Int((precipitationChance * 100).rounded())
        return percent >= 30 ? percent : nil
    }

    private static let symbolNames: [String: String] = [
        "Clear": "sun.max.fill",
        "MostlyClear": "sun.max.fill",
        "Hot": "thermometer.sun.fill",
        "PartlyCloudy": "cloud.sun.fill",
        "MostlyCloudy": "cloud.fill",
        "Cloudy": "cloud.fill",
        "Foggy": "cloud.fog.fill",
        "Haze": "sun.haze.fill",
        "Smoky": "smoke.fill",
        "BlowingDust": "sun.dust.fill",
        "Breezy": "wind",
        "Windy": "wind",
        "Drizzle": "cloud.drizzle.fill",
        "Rain": "cloud.rain.fill",
        "SunShowers": "cloud.sun.rain.fill",
        "HeavyRain": "cloud.heavyrain.fill",
        "FreezingDrizzle": "cloud.sleet.fill",
        "FreezingRain": "cloud.sleet.fill",
        "Sleet": "cloud.sleet.fill",
        "WintryMix": "cloud.sleet.fill",
        "Hail": "cloud.hail.fill",
        "IsolatedThunderstorms": "cloud.bolt.rain.fill",
        "ScatteredThunderstorms": "cloud.bolt.rain.fill",
        "Thunderstorms": "cloud.bolt.rain.fill",
        "StrongStorms": "cloud.bolt.rain.fill",
        "Flurries": "cloud.snow.fill",
        "SunFlurries": "sun.snow.fill",
        "Snow": "cloud.snow.fill",
        "HeavySnow": "cloud.snow.fill",
        "BlowingSnow": "wind.snow",
        "Blizzard": "wind.snow",
        "Frigid": "thermometer.snowflake",
        "Hurricane": "hurricane",
        "TropicalStorm": "tropicalstorm"
    ]
}
