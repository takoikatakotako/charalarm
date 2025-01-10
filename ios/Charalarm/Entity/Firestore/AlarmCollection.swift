// import Foundation
// import FirebaseFirestore
//
// struct AlarmCollection: Hashable {
//    let id: String
//    let userId: String
//    let type: String
//    let enable: Bool
//    let name: String
//    let hour: Int
//    let minute: Int
//    let time: String
//    
//    let sunday: Bool
//    let monday: Bool
//    let tuesday: Bool
//    let wednesday: Bool
//    let thursday: Bool
//    let friday: Bool
//    let saturday: Bool
//    
//    let charaId: String
//    let charaName: String
//    let voiceFilePath: String
//
//    
//    init(document: QueryDocumentSnapshot) throws {
//        let data = document.data()
//        guard
//            let userId = data["userId"] as? String,
//            let type = data["type"] as? String,
//            let enable = data["enable"] as? String,
//            let name = data["name"] as? String
//        else {
//            throw CharalarmError.clientError
//        }
//        
//        self.id = document.documentID
//        self.iosPushToken = iosPushToken
//        self.iosPushTokenEndpoint = iosPushTokenEndpoint
//        self.iosVoIPPushToken = iosVoIPPushToken
//        self.iosVoIPPushTokenEndpoint = iosVoIPPushTokenEndpoint
//    }
// }
//
//
//
// {
//  "alarmID":"{UUID}",
//  "userID":"{UUID}",
//  "alarmType":"{VOICE_CALL_ALARM or NEWS_CALL_ALARM or CALENDER_CALL_ALARM}",
//  "alarmEnable":"{Bool}",
//  "alarmName":"{String}",
//  "alarmHour":"{Int}",
//  "alarmMinute":"{Int}",
//  "alarmTime":"{String}",
//  "charaID":"{String}",
//  "charaName":"{String}",
//  "voiceFileURL":"{String}",
//  "sunday":"{Bool}",
//  "monday":"{Bool}",
//  "tuesday":"{Bool}",
//  "wednesday":"{Bool}",
//  "thursday":"{Bool}",
//  "friday":"{Bool}",
//  "saturday":"{Bool}"
// }
