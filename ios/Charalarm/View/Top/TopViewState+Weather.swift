import Foundation

// MARK: - 天気

extension TopViewState {
    /// 取った天気を使い回す長さ。サーバも地域ごとに 1 時間キャッシュしている
    private static let weatherRefreshInterval: TimeInterval = 30 * 60

    /// 天気を取り直す。設定で地域を変えたかもしれないので、地域も読み直す
    func refreshWeather() {
        let region = UserDefaultsRepository().getWeatherRegion()
        if region != weatherRegion {
            weatherRegion = region
            todayWeather = nil
            weatherFetchedAt = nil
        }
        guard let region else { return }
        if let fetchedAt = weatherFetchedAt, Date().timeIntervalSince(fetchedAt) < Self.weatherRefreshInterval {
            return
        }

        let keychainRepository = KeychainRepository()
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else { return }
        weatherFetchedAt = Date()
        Task {
            do {
                let weather = try await APIRepository().fetchTodayWeather(userID: userID, authToken: authToken, region: region.code)
                // 取っているあいだに地域を変えていたら使わない
                guard weatherRegion == region else { return }
                todayWeather = weather
            } catch {
                // 天気が出ないだけなので、知らせずにおく。次にトップを開いたときに取り直す
                weatherFetchedAt = nil
                CharalarmLogger.error("天気を取れませんでした", error: error)
            }
        }
    }

    /// トップのメニューで地域を選んだ（設定の「天気の地域」も変わる）
    func selectWeatherRegion(_ region: WeatherRegion?) {
        UserDefaultsRepository().setWeatherRegion(region)
        refreshWeather()
    }
}
