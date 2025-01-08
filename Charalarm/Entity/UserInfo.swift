import UIKit

struct UserInfo: Identifiable, Hashable {
    var id: UUID {
        return userID
    }
    let userID: UUID
    let authToken: String
    let platform: String
    let premiumPlan: Bool
    let iOSPlatformInfo: UserInfoIOSPlatformInfo
}

struct UserInfoIOSPlatformInfo: Hashable {
    let pushToken: String
    let pushTokenSNSEndpoint: String
    let voIPPushToken: String
    let voIPPushTokenSNSEndpoint: String
}
