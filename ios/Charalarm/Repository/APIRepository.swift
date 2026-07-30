import Foundation

enum APIRepositoryError: Error {
    case invalidURL
}

struct APIRepository {}

extension APIRepository {
    func postPushTokenAddPushToken(userID: String, authToken: String, pushToken: PushTokenRequest) async throws {
        let path = "/push-token/ios/push/add"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable = pushToken
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }

    func postPushTokenAddVoIPPushToken(userID: String, authToken: String, pushToken: PushTokenRequest) async throws {
        let path = "/push-token/ios/voip-push/add"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable = pushToken
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }
}

extension APIRepository {
    func getUserInfo(userID: String, authToken: String) async throws -> UserInfo {
        let path = "/user/info"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable? = nil
        let userInfoResponse: UserInfoResponse = try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)

        // 変換
        let iOSPlatformInfo = UserInfoIOSPlatformInfo(
            pushToken: userInfoResponse.iOSPlatformInfo.pushToken,
            pushTokenSNSEndpoint: userInfoResponse.iOSPlatformInfo.pushTokenSNSEndpoint,
            voIPPushToken: userInfoResponse.iOSPlatformInfo.voIPPushToken,
            voIPPushTokenSNSEndpoint: userInfoResponse.iOSPlatformInfo.voIPPushTokenSNSEndpoint
        )
        return UserInfo(
            userID: userInfoResponse.userID,
            authToken: userInfoResponse.authToken,
            platform: userInfoResponse.platform,
            premiumPlan: userInfoResponse.premiumPlan,
            iOSPlatformInfo: iOSPlatformInfo)
    }

    func postUserUpdatePremium(userID: String, authToken: String, requestBody: UserUpdatePremiumPlanRequest) async throws {
        let path = "/user/update-premium"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable? = requestBody
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }

    func postUserSignup(request: UserSignUpRequest) async throws {
        let path = "/user/signup"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.defaultHeader
        let requestBody: Encodable? = request
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }

    func postUserWithdraw(userID: String, authToken: String) async throws {
        let path = "/user/withdraw"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable? = nil
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }
}

extension APIRepository {
    func getCharaList() async throws -> [Chara] {
        let path = "/chara/list"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.defaultHeader
        let requestBody: Encodable? = nil
        let charaResponses: [CharaResponse] = try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)
        return charaResponses.map { Chara(charaResponse: $0) }
    }

    func fetchCharacter(charaID: String) async throws -> Chara {
        let path = "/chara/id/\(charaID)"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.defaultHeader
        let requestBody: Encodable? = nil
        let charaResponse: CharaResponse = try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)
        return Chara(charaResponse: charaResponse)
    }
}

extension APIRepository {
    func fetchMaintenance() async throws -> Bool {
        let path = "/maintenance"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.defaultHeader
        let requestBody: Request? = nil
        let response: MaintenanceResponse = try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)
        return response.maintenance
    }

    func fetchRequireVersion() async throws -> String {
        let path = "/require"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.defaultHeader
        let requestBody: Request? = nil
        let response: RequireVersionResponse = try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)
        return response.iosVersion
    }
}

extension APIRepository {
    func fetchAlarms(userID: String, authToken: String) async throws -> [AlarmResponse] {
        let path = "/alarm/list"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Request? = nil
        return try await APIClient().request(url: url, httpMethod: .get, requestHeader: requestHeader, requestBody: requestBody)
    }

    func addAlarm(userID: String, authToken: String, requestBody: AlarmAddRequest) async throws {
        let path = "/alarm/add"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Request? = requestBody
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }

    func editAlarm(userID: String, authToken: String, requestBody: AlarmEditRequest) async throws {
        let path = "/alarm/edit"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Request? = requestBody
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }

    func deleteAlarm(userID: String, authToken: String, requestBody: AlarmDeleteRequest) async throws {
        let path = "/alarm/delete"
        let url = try createURL(path: path)
        let requestHeader = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Request? = requestBody
        let _: MessageResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
    }
}

extension APIRepository {
    /// ずんだもんとの会話応答を backend `/chat` から取得する。
    func postChat(userID: String, authToken: String, messages: [ChatMessage]) async throws -> String {
        let path = "/chat"
        let url = try createURL(path: path)
        let requestHeader: [String: String] = APIHeader.createAuthorizationRequestHeader(userID: userID, authToken: authToken)
        let requestBody: Encodable? = ChatRequest(messages: messages)
        let chatResponse: ChatResponse = try await APIClient().request(url: url, httpMethod: .post, requestHeader: requestHeader, requestBody: requestBody)
        return chatResponse.message
    }
}

// MARK: - Private

private extension APIRepository {
    func createURL(path: String) throws -> URL {
        guard let url = URL(string: Variables.apiEndpoint + path) else {
            throw APIRepositoryError.invalidURL
        }
        return url
    }
}
