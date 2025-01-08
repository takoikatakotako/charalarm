import Foundation
import FirebaseFirestore

struct UserCollection: Hashable {
    let id: String
    let iosPushToken: String
    let iosPushTokenEndpoint: String
    let iosVoIPPushToken: String
    let iosVoIPPushTokenEndpoint: String

    init(document: QueryDocumentSnapshot) throws {
        let data = document.data()
        guard
            let iosPushToken = data["iosPushToken"] as? String,
            let iosPushTokenEndpoint = data["iosPushTokenEndpoint"] as? String,
            let iosVoIPPushToken = data["iosVoIPPushToken"] as? String,
            let iosVoIPPushTokenEndpoint = data["iosVoIPPushTokenEndpoint"] as? String
        else {
            throw CharalarmError.clientError
        }

        self.id = document.documentID
        self.iosPushToken = iosPushToken
        self.iosPushTokenEndpoint = iosPushTokenEndpoint
        self.iosVoIPPushToken = iosVoIPPushToken
        self.iosVoIPPushTokenEndpoint = iosVoIPPushTokenEndpoint
    }
}

//
//
//
// {
//  "userID":"{UUID}",
//  "authToken":"{UUID}",
//  "iosVoIPPushTokens":{
//    "token":"{iOSのVoIPプッシュ通知のトークン}",
//    "snsEndpointArn":"{iOSのVoIPプッシュ通知のPlatformApplicationのエンドポイント}"
//  },
//  "iosPushTokens":{
//    "token":"{iOSのVoIPプッシュ通知のトークン}",
//    "snsEndpointArn":"{iOSのVoIPプッシュ通知のPlatformApplicationのエンドポイント}"
//  }
// }
