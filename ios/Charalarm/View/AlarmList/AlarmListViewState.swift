import Foundation

class AlarmListViewState: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var sheet: AlarmListViewSheetItem?
    @Published var alert: AlarmListViewAlertItem?
    @Published var showingIndicator: Bool = true

    private let apiRepository = APIRepository()
    private let keychainRepository: KeychainRepository = KeychainRepository()
    private let userDefaultsRepository: UserDefaultsRepository = UserDefaultsRepository()

    var isShowingADs: Bool {
        if userDefaultsRepository.getEnablePremiumPlan() {
            return false
        } else {
            return true
        }
    }

    func addAlarmButtonTapped() {
        if alarms.isEmpty {
            sheet = .alarmDetailForCreate
        } else if 0 < alarms.count && alarms.count <= 10 {
            if userDefaultsRepository.getEnablePremiumPlan() {
                sheet = .alarmDetailForCreate
            } else {
                alert = .error(UUID(), String(localized: "alarm-list-too-much"))
            }
        } else {
            alert = .error(UUID(), String(localized: "alarm-you-can-create-up-to-three-alarms"))
        }
    }

    func createNewAlarm() -> Alarm {
        let alarmID = UUID()
        let date = Date()
        let name = String(localized: "alarm-new-alarm")
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeDifference = Decimal(TimeZone.current.secondsFromGMT(for: date) / 60 / 60)
        let enable = true

        return Alarm(
            alarmID: alarmID,
            type: .IOS_VOIP_PUSH_NOTIFICATION,
            enable: enable,
            name: name,
            hour: hour,
            minute: minute,
            timeDifference: timeDifference,
            charaName: "",
            charaID: "",
            voiceFileName: "",
            sunday: true,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: true
        )
    }

    func onAppear() {
        Task { @MainActor in
            showingIndicator = true
            guard let userID = keychainRepository.getUserID(),
                  let authToken = keychainRepository.getAuthToken() else {
                    alert = .error(UUID(), String(localized: "error-failed-to-get-authentication-information"))
                return
            }

            // Fetch Alarm
            do {
                let alarms = try await apiRepository.fetchAlarms(userID: userID, authToken: authToken)
                self.showingIndicator = false
                self.alarms = alarms.map { $0.toAlarm() }
            } catch {
                self.alert = .error(UUID(), String(localized: "alarm-failed-to-get-the-alarm-list"))
            }

            // Set VoIP Push
            do {
                let pushToken = PushTokenRequest(pushToken: Variables.shared.voipPushToken)
                try await apiRepository.postPushTokenAddVoIPPushToken(userID: userID, authToken: authToken, pushToken: pushToken)
            } catch {
            }
        }
    }

    func fetchAlarms() {
        Task { @MainActor in
            showingIndicator = true
            guard let userID = keychainRepository.getUserID(),
                  let authToken = keychainRepository.getAuthToken() else {
                    alert = .error(UUID(), String(localized: "error-failed-to-get-authentication-information"))
                return
            }

            do {
                let alarms = try await apiRepository.fetchAlarms(userID: userID, authToken: authToken)
                self.showingIndicator = false
                self.alarms = alarms.map { $0.toAlarm() }
            } catch {
                self.alert = .error(UUID(), String(localized: "alarm-failed-to-get-the-alarm-list"))
            }
        }
    }

    func updateAlarmEnable(alarmId: UUID, isEnable: Bool) {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            alert = .error(UUID(), String(localized: "error-failed-to-get-authentication-information"))
            return
        }

        guard let index = alarms.firstIndex(where: { $0.alarmID == alarmId }) else {
            return
        }

        alarms[index].enable = isEnable
        let alarm = alarms[index]
        Task { @MainActor in
            do {
                let requestBody = AlarmEditRequest(alarm: alarm.toAlarmRequest(userID: UUID(uuidString: userID)!))
                try await apiRepository.editAlarm(userID: userID, authToken: authToken, requestBody: requestBody)
            } catch {
                alert = .error(UUID(), String(localized: "alarm-failed-to-edit-the-alarm"))
            }
        }
    }

    func editAlarm(alarm: Alarm) {
        sheet = .alarmDetailForEdit(alarm)
    }
}
