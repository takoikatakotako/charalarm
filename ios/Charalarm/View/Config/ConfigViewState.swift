import SwiftUI

@Observable class ConfigViewState {
    var character: Chara?
    var showingAlert = false
    var alertMessage = ""
    var showingResetAlert = false
    var showingSubscriptionSheet = false
    /// 会話で今日の予定を使う。オンにするときにカレンダーの許可を求める
    private(set) var useCalendarInConversation = UserDefaultsRepository().getUseCalendarInConversation()
        && CalendarRepository().isAuthorized

    func setUseCalendarInConversation(_ use: Bool) {
        guard use else {
            useCalendarInConversation = false
            UserDefaultsRepository().setUseCalendarInConversation(false)
            return
        }
        Task { @MainActor in
            let granted = await CalendarRepository().requestAccess()
            useCalendarInConversation = granted
            UserDefaultsRepository().setUseCalendarInConversation(granted)
            if !granted {
                alertMessage = String(localized: "config-calendar-access-denied")
                showingAlert = true
            }
        }
    }

    /// 電話の最初に、キャラのほうから今日の予定に触れる。オンにするときにカレンダーの許可を求める
    private(set) var mentionScheduleOnCall = UserDefaultsRepository().getMentionScheduleOnCall()
        && CalendarRepository().isAuthorized

    func setMentionScheduleOnCall(_ mention: Bool) {
        guard mention else {
            mentionScheduleOnCall = false
            UserDefaultsRepository().setMentionScheduleOnCall(false)
            return
        }
        Task { @MainActor in
            let granted = await CalendarRepository().requestAccess()
            mentionScheduleOnCall = granted
            UserDefaultsRepository().setMentionScheduleOnCall(granted)
            if !granted {
                alertMessage = String(localized: "config-calendar-access-denied")
                showingAlert = true
            }
        }
    }

    /// キャラと会話する言語。キャラが話せなければ、そのキャラの言語で会話する
    var conversationLanguage: ConversationLanguage = UserDefaultsRepository().getConversationLanguage() {
        didSet {
            UserDefaultsRepository().setConversationLanguage(conversationLanguage)
        }
    }

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
        return userDefaultsRepository.getCharaID() ?? ""
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
            self.alertMessage = String(localized: "error-failed-to-get-authentication-information")
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
