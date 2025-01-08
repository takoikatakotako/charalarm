import UIKit

struct AlarmResponse: Response {
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
}

extension AlarmResponse {
    func toAlarm() -> Alarm {
        return Alarm(
            alarmID: alarmID,
            type: .IOS_VOIP_PUSH_NOTIFICATION,
            enable: enable,
            name: name,
            hour: hour,
            minute: minute,
            timeDifference: timeDifference,
            charaName: charaName,
            charaID: charaID,
            voiceFileName: voiceFileName,
            sunday: sunday,
            monday: monday,
            tuesday: tuesday,
            wednesday: wednesday,
            thursday: thursday,
            friday: friday,
            saturday: saturday
        )
    }
}
