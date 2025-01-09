import Foundation

struct UserInfoResponse: Response {
    let userID: UUID
    let authToken: String
    let platform: String
    let premiumPlan: Bool
    let iOSPlatformInfo: UserInfoIOSPlatformInfoResponse
}

struct UserInfoIOSPlatformInfoResponse: Response {
    let pushToken: String
    let pushTokenSNSEndpoint: String
    let voIPPushToken: String
    let voIPPushTokenSNSEndpoint: String
}
