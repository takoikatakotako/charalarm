import SwiftUI

@Observable class ErrorViewState {
    private let keychainRepository = KeychainRepository()
    private let authUseCase = AuthUseCase()

    func reset() {
        authUseCase.reset()
        NotificationCenter.default.post(name: NSNotification.didReset, object: self, userInfo: nil)
    }
}
