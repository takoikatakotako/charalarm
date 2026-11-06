import SwiftUI

/// トップの上に出す今日の天気。押すと地域を選べる。
/// WeatherKit の利用条件にしたがい、Apple Weather の表記を出し、メニューにデータ提供元のページを置く
struct TopWeatherMenu: View {
    let weather: TodayWeather?
    let region: WeatherRegion?
    let onSelectRegion: (WeatherRegion?) -> Void

    private static let legalAttributionURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    var body: some View {
        Menu {
            Picker(String(localized: "config-weather-region"), selection: Binding(get: { region }, set: onSelectRegion)) {
                Text(String(localized: "config-weather-region-none")).tag(WeatherRegion?.none)
                ForEach(WeatherRegion.all) { region in
                    Text(region.displayName).tag(WeatherRegion?.some(region))
                }
            }
            .pickerStyle(.menu)
            if weather != nil {
                Link(String(localized: "config-weather-data-sources"), destination: Self.legalAttributionURL)
            }
        } label: {
            if let weather {
                weatherLabel(weather)
            } else {
                TopPillLabel(systemImageName: "cloud.sun.fill", text: region?.displayName ?? String(localized: "config-weather-region"))
            }
        }
    }

    private func weatherLabel(_ weather: TodayWeather) -> some View {
        HStack(spacing: 6) {
            Image(systemName: weather.symbolName)
                .symbolRenderingMode(.multicolor)
            Text(verbatim: "\(Int(weather.temperatureMax.rounded()))° / \(Int(weather.temperatureMin.rounded()))°")
                .monospacedDigit()
            if let percent = weather.notablePrecipitationPercent {
                HStack(spacing: 2) {
                    Image(systemName: "umbrella.fill")
                    Text(verbatim: "\(percent)%")
                        .monospacedDigit()
                }
            }
            Text(verbatim: "\u{F8FF}Weather")
                .font(.caption2.weight(.semibold))
                .opacity(0.8)
        }
        .font(.footnote.bold())
        .foregroundStyle(Color.white)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
        .background(.black.opacity(0.3), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(region?.displayName ?? "") \(Int(weather.temperatureMax.rounded()))° / \(Int(weather.temperatureMin.rounded()))°, Apple Weather"))
    }
}
