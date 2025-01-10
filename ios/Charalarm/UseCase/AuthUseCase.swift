import Foundation

protocol AuthUseCaseProtcol {
    func withdraw(userID: String, authToken: String) async throws
    func reset()
}

struct AuthUseCase: AuthUseCaseProtcol {
    private let keychainRepository: KeychainRepository = KeychainRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let apiRepository = APIRepository()

    // ユーザー退会
    func withdraw(userID: String, authToken: String) async throws {
        try await apiRepository.postUserWithdraw(userID: userID, authToken: authToken)
        try keychainRepository.setUserID(userID: nil)
        try keychainRepository.setAuthToken(authToken: nil)
        userDefaultsRepository.setDefaultCharaDomain()
        userDefaultsRepository.setDefaultCharaName()
    }

    // ユーザー情報リセット、退会失敗時などの使用を想定
    func reset() {
        try? keychainRepository.setUserID(userID: nil)
        try? keychainRepository.setAuthToken(authToken: nil)
        userDefaultsRepository.setDefaultCharaDomain()
        userDefaultsRepository.setDefaultCharaName()
    }
}
