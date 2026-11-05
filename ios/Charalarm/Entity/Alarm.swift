import UIKit

struct Alarm: Identifiable, Hashable {
    var id: UUID {
        return alarmID
    }
    var alarmID: UUID
    var type: AlarmType
    var enable: Bool
    var name: String
    var hour: Int
    var minute: Int
    var timeDifference: Decimal
    var charaName: String
    var charaID: String
    var voiceFileName: String
    var sunday: Bool
    var monday: Bool
    var tuesday: Bool
    var wednesday: Bool
    var thursday: Bool
    var friday: Bool
    var saturday: Bool
    /// 電話（AI 会話）の設定。nil なら、アプリ共通の設定を使う（設定の無い古いアラーム）
    var call: CallSettings?
}

extension Alarm {
    func toAlarmRequest(userID: UUID) -> AlarmRequest {
        return AlarmRequest(
            alarmID: alarmID,
            userID: userID,
            type: type.rawValue,
            enable: enable,
            name: name,
            hour: hour,
            minute: minute,
            timeDifference: timeDifference,
            charaID: charaID,
            charaName: charaName,
            voiceFileName: voiceFileName,
            sunday: sunday,
            monday: monday,
            tuesday: tuesday,
            wednesday: wednesday,
            thursday: thursday,
            friday: friday,
            saturday: saturday,
            call: call
        )
    }
}

enum AlarmType: String {
    case IOS_PUSH_NOTIFICATION = "IOS_PUSH_NOTIFICATION"
    case IOS_VOIP_PUSH_NOTIFICATION = "IOS_VOIP_PUSH_NOTIFICATION"
}
