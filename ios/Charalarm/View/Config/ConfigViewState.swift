import UIKit
import SwiftUI

class ConfigViewState: ObservableObject {
    @Published var character: Chara?
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var showingResetAlert = false
    @Published var showingSubscriptionSheet = false

    private let keychainRepository: KeychainRepository = KeychainRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let appUseCase = AppUseCase()
    private let apiRepository = APIRepository()
    private let authUseCase = AuthUseCase()
    private let openURLRepository = OpenURLRepository()

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

    func openAppSetting() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
    }

    func resetButtonTapped() {
        showingResetAlert = true
    }

    func openUrlString(string: String) {
        guard let url = URL(string: string) else {
            return
        }
        UIApplication.shared.open(url)
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

    func openInquiry() {
        let url = openURLRepository.inqueryURL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openCharacterAdditionRequest() {
        let url = openURLRepository.characterAdditionRequestURL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func getVersion() -> String {
        return "\(appUseCase.appVersion)(\(appUseCase.appBuild))"
    }
}
