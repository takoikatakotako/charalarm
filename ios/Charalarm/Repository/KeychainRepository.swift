import Foundation
import KeychainAccess

protocol KeychainRepositoryProtcol {
    func setUserID(userID: UUID?) throws
    func setAuthToken(authToken: UUID?) throws
    func getUserID() -> String?
    func getAuthToken() -> String?
}

struct KeychainRepository: KeychainRepositoryProtcol {
    // Key
    private let USER_ID = "USER_ID"
    private let AUTH_TOKEN = "AUTH_TOKEN"
    private let ANONYMOUS_USER_NAME = "ANONYMOUS_USER_NAME"
    private let ANONYMOUS_AUTH_TOKEN = "ANONYMOUS_AUTH_TOKEN"

    func setUserID(userID: UUID?) throws {
        try set(key: ANONYMOUS_USER_NAME, value: userID?.uuidString ?? "")
        try set(key: USER_ID, value: userID?.uuidString ?? "")
    }

    func setAuthToken(authToken: UUID?) throws {
        try set(key: ANONYMOUS_AUTH_TOKEN, value: authToken?.uuidString ?? "")
        try set(key: AUTH_TOKEN, value: authToken?.uuidString ?? "")
    }

    func getUserID() -> String? {
        if let userID = get(key: USER_ID) {
            return userID
        }
        return get(key: ANONYMOUS_USER_NAME)
    }

    func getAuthToken() -> String? {
        if let authToken = get(key: AUTH_TOKEN) {
            return authToken
        }
        return get(key: ANONYMOUS_AUTH_TOKEN)
    }

    private func set(key: String, value: String) throws {
        let keychain = Keychain()
        try keychain.set(value, key: key)
    }

    private func get(key: String) -> String? {
        let keychain = Keychain()
        guard let value = try? keychain.get(key), value.isNotEmpty else {
            return nil
        }
        return value
    }
}
