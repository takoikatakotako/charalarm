import Foundation

/// モーニングコールで天気を伝える地域。設定画面で選ぶ（アプリ共通）。
/// 端末の位置は使わず、/chat には都道府県コードだけを送る。天気はサーバが代表地点（県庁所在地）のものを取る。
/// code はサーバの weather.Region と同じ（JIS X 0401）。
struct WeatherRegion: Identifiable, Hashable {
    let code: String
    let japaneseName: String
    let englishName: String

    var id: String { code }

    /// 設定画面に出す名前。日本語以外では英語の名前
    var displayName: String {
        Locale.current.language.languageCode == .japanese ? japaneseName : englishName
    }

    static func find(code: String) -> WeatherRegion? {
        all.first { $0.code == code }
    }

    static let all: [WeatherRegion] = [
        WeatherRegion(code: "01", japaneseName: "北海道", englishName: "Hokkaido"),
        WeatherRegion(code: "02", japaneseName: "青森県", englishName: "Aomori"),
        WeatherRegion(code: "03", japaneseName: "岩手県", englishName: "Iwate"),
        WeatherRegion(code: "04", japaneseName: "宮城県", englishName: "Miyagi"),
        WeatherRegion(code: "05", japaneseName: "秋田県", englishName: "Akita"),
        WeatherRegion(code: "06", japaneseName: "山形県", englishName: "Yamagata"),
        WeatherRegion(code: "07", japaneseName: "福島県", englishName: "Fukushima"),
        WeatherRegion(code: "08", japaneseName: "茨城県", englishName: "Ibaraki"),
        WeatherRegion(code: "09", japaneseName: "栃木県", englishName: "Tochigi"),
        WeatherRegion(code: "10", japaneseName: "群馬県", englishName: "Gunma"),
        WeatherRegion(code: "11", japaneseName: "埼玉県", englishName: "Saitama"),
        WeatherRegion(code: "12", japaneseName: "千葉県", englishName: "Chiba"),
        WeatherRegion(code: "13", japaneseName: "東京都", englishName: "Tokyo"),
        WeatherRegion(code: "14", japaneseName: "神奈川県", englishName: "Kanagawa"),
        WeatherRegion(code: "15", japaneseName: "新潟県", englishName: "Niigata"),
        WeatherRegion(code: "16", japaneseName: "富山県", englishName: "Toyama"),
        WeatherRegion(code: "17", japaneseName: "石川県", englishName: "Ishikawa"),
        WeatherRegion(code: "18", japaneseName: "福井県", englishName: "Fukui"),
        WeatherRegion(code: "19", japaneseName: "山梨県", englishName: "Yamanashi"),
        WeatherRegion(code: "20", japaneseName: "長野県", englishName: "Nagano"),
        WeatherRegion(code: "21", japaneseName: "岐阜県", englishName: "Gifu"),
        WeatherRegion(code: "22", japaneseName: "静岡県", englishName: "Shizuoka"),
        WeatherRegion(code: "23", japaneseName: "愛知県", englishName: "Aichi"),
        WeatherRegion(code: "24", japaneseName: "三重県", englishName: "Mie"),
        WeatherRegion(code: "25", japaneseName: "滋賀県", englishName: "Shiga"),
        WeatherRegion(code: "26", japaneseName: "京都府", englishName: "Kyoto"),
        WeatherRegion(code: "27", japaneseName: "大阪府", englishName: "Osaka"),
        WeatherRegion(code: "28", japaneseName: "兵庫県", englishName: "Hyogo"),
        WeatherRegion(code: "29", japaneseName: "奈良県", englishName: "Nara"),
        WeatherRegion(code: "30", japaneseName: "和歌山県", englishName: "Wakayama"),
        WeatherRegion(code: "31", japaneseName: "鳥取県", englishName: "Tottori"),
        WeatherRegion(code: "32", japaneseName: "島根県", englishName: "Shimane"),
        WeatherRegion(code: "33", japaneseName: "岡山県", englishName: "Okayama"),
        WeatherRegion(code: "34", japaneseName: "広島県", englishName: "Hiroshima"),
        WeatherRegion(code: "35", japaneseName: "山口県", englishName: "Yamaguchi"),
        WeatherRegion(code: "36", japaneseName: "徳島県", englishName: "Tokushima"),
        WeatherRegion(code: "37", japaneseName: "香川県", englishName: "Kagawa"),
        WeatherRegion(code: "38", japaneseName: "愛媛県", englishName: "Ehime"),
        WeatherRegion(code: "39", japaneseName: "高知県", englishName: "Kochi"),
        WeatherRegion(code: "40", japaneseName: "福岡県", englishName: "Fukuoka"),
        WeatherRegion(code: "41", japaneseName: "佐賀県", englishName: "Saga"),
        WeatherRegion(code: "42", japaneseName: "長崎県", englishName: "Nagasaki"),
        WeatherRegion(code: "43", japaneseName: "熊本県", englishName: "Kumamoto"),
        WeatherRegion(code: "44", japaneseName: "大分県", englishName: "Oita"),
        WeatherRegion(code: "45", japaneseName: "宮崎県", englishName: "Miyazaki"),
        WeatherRegion(code: "46", japaneseName: "鹿児島県", englishName: "Kagoshima"),
        WeatherRegion(code: "47", japaneseName: "沖縄県", englishName: "Okinawa")
    ]
}
