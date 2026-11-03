import Foundation

/// キャラとの電話を自動で終える時間。設定画面で選ぶ（アプリ共通）。
/// 会話が始まってからこの時間がたったら、キャラがお別れを言って電話を切る。
enum CallTimeLimit: Int, CaseIterable, Identifiable {
    case seconds30 = 30
    case seconds60 = 60
    case seconds90 = 90
    case seconds120 = 120
    case seconds180 = 180

    static let `default`: CallTimeLimit = .seconds120

    /// 上限でお別れを始めてから、これだけたっても終わらなければ、お別れの途中でも切る
    static let farewellGracePeriod: TimeInterval = 20

    var id: Int { rawValue }

    /// お別れを始める時間（会話が始まってから）
    var duration: TimeInterval { TimeInterval(rawValue) }

    /// 何があっても電話を切る時間（会話が始まってから）
    var hardDeadline: TimeInterval { duration + Self.farewellGracePeriod }

    /// 設定画面に出す名前（「1分 30秒」「1 minute, 30 seconds」）
    var displayName: String {
        Duration.seconds(rawValue).formatted(.units(allowed: [.minutes, .seconds], width: .wide))
    }
}
