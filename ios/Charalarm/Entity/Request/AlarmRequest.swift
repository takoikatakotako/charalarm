import Foundation

struct AlarmRequest: Encodable {
    let alarmID: UUID
    let userID: UUID
    let type: String
    let enable: Bool
    let name: String
    let hour: Int
    let minute: Int
    let timeDifference: Decimal
    let charaID: String
    let charaName: String
    let voiceFileName: String
    let sunday: Bool
    let monday: Bool
    let tuesday: Bool
    let wednesday: Bool
    let thursday: Bool
    let friday: Bool
    let saturday: Bool
    /// 電話（AI 会話）の設定。nil なら送らない（アプリ共通の設定を使う）
    let call: CallSettings?
}
