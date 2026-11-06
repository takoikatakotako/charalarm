import Foundation

/// /weather のリクエスト。地域は URL に入れるとアクセスログに残るので、ボディで送る
struct WeatherRequest: Request {
    /// 都道府県コード ("01"〜"47")
    let region: String
}
