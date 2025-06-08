import SwiftUI

class ErrorViewState: ObservableObject {
    private let keychainRepository = KeychainRepository()
    private let authUseCase = AuthUseCase()

    func reset() {
        authUseCase.reset()
        NotificationCenter.default.post(name: NSNotification.didReset, object: self, userInfo: nil)
    }
}
