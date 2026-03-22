import SwiftUI

@Observable class ConfigViewState {
    var character: Chara?
    var showingAlert = false
    var alertMessage = ""
    var showingResetAlert = false
    var showingSubscriptionSheet = false

    private let keychainRepository: KeychainRepository = KeychainRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let appUseCase = AppUseCase()
    private let apiRepository = APIRepository()
    private let authUseCase = AuthUseCase()

    var isShowingADs: Bool {
        if userDefaultsRepository.getEnablePremiumPlan() {
            return false
        } else {
            return true
        }
    }

    var versionString: String {
        return getVersion()
    }

    var charaDomain: String {
        guard let characterDomain = userDefaultsRepository.getCharaID() else {
            fatalError("CHARA_DOMAIN が取得できませんでした")
        }
        return characterDomain
    }

    func subscriptionButtonTapped() {
        showingSubscriptionSheet = true
    }

    func resetButtonTapped() {
        showingResetAlert = true
    }

    func withdraw() {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            self.alertMessage = "不明なエラーです（UserDefaultsに匿名ユーザー名とかがない）"
            self.showingAlert = true
            return
        }

        Task { @MainActor in
            do {
                try await authUseCase.withdraw(userID: userID, authToken: authToken)
            } catch {
                authUseCase.reset()
            }
            NotificationCenter.default.post(name: NSNotification.didReset, object: self, userInfo: nil)
        }
    }

    private func getVersion() -> String {
        return "\(appUseCase.appVersion)(\(appUseCase.appBuild))"
    }
}
