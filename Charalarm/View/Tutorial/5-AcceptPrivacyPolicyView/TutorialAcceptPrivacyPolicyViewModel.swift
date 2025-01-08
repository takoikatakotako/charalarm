import SwiftUI
import AdSupport
import AppTrackingTransparency

class TutorialAcceptPrivacyPolicyViewModel: ObservableObject {
    @Published var accountCreated = false
    @Published var creatingAccount = false
    @Published var showingAlert = false
    @Published var alertMessage = ""

    private let userID = UUID()
    private let authToken = UUID()
    private let keychainRepository: KeychainRepository = KeychainRepository()
    private let apiRepository = APIRepository()

    func openPrivacyPolicy() {
        guard let url = URL(string: PrivacyPolicyUrlString) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func signUp() {
        guard !creatingAccount else {
            return
        }

        creatingAccount = true

        let delegate = UIApplication.shared.delegate as? AppDelegate
        let optionalPushToken = delegate?.model.pushToken
        let optionalVoIPPushToken = delegate?.model.voipPushToken

        Task { @MainActor in
            // ここでユーザー登録してトークンを設定する
            do {
                // SignUp
                try await apiRepository.postUserSignup(request: UserSignUpRequest(userID: userID.uuidString, authToken: authToken.uuidString, platform: "iOS"))

                // Set KeyChain
                try keychainRepository.setUserID(userID: userID)
                try keychainRepository.setAuthToken(authToken: authToken)

                // Set Push Token
                if let token = optionalPushToken {
                    let pushToken = PushTokenRequest(pushToken: token)
                    try await apiRepository.postPushTokenAddPushToken(userID: userID.uuidString, authToken: authToken.uuidString, pushToken: pushToken)
                }

                // Set VoIP Push Token
                if let token = optionalVoIPPushToken {
                    let voipPushToken = PushTokenRequest(pushToken: token)
                    try await apiRepository.postPushTokenAddVoIPPushToken(userID: userID.uuidString, authToken: authToken.uuidString, pushToken: voipPushToken)
                }

                accountCreated = true
            } catch {
                alertMessage = String(localized: "tutorial-failed-to-save-user-information")
                showingAlert = true
            }
            creatingAccount = false
        }
    }

    private func trackingAuthorizationNotDetermined() -> Bool {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized:
            return false
        case .denied:
            return false
        case .restricted:
            return false
        case .notDetermined:
            return true
        @unknown default:
            return false
        }
    }
}
