import Foundation
import SwiftUI
import Combine

@Observable class AlarmDetailViewState {
    var alarm: Alarm
    var characters: [Chara] = []
    var showingAlert = false
    var alertMessage = ""
    var sheet: AlarmDetailViewSheetItem?
    var selectedChara: Chara?
    var selectedCharaCall: CharaCall?
    var showingIndicator: Bool = false
    var dismiss: Bool = false

    var dismissRequest: AnyPublisher<Void, Never> {
        dismissSubject.eraseToAnyPublisher()
    }
    private let dismissSubject = PassthroughSubject<Void, Never>()

    let type: AlarmDetailViewTyep
//    private let alarmRepository: AlarmRepository = AlarmRepository()
    private let apiRepository = APIRepository()
    private let keychainRepository: KeychainRepository = KeychainRepository()

    var timeDefferenceString: String {
        if alarm.timeDifference >= 0 {
            return "GMT+\(abs(alarm.timeDifference))"
        } else {
            return "GMT-\(abs(alarm.timeDifference))"
        }
    }

    var alarmTimeString: String {
        let sign = alarm.timeDifference >= 0 ? "+" : "-"
        return "\(String(format: "%02d", alarm.hour)):\(String(format: "%02d", alarm.minute))(GMT\(sign)\(abs(alarm.timeDifference)))"
    }

    init(alarm: Alarm, type: AlarmDetailViewTyep) {
        self.alarm = alarm
        self.type = type
    }

    func onAppear() {
        Task { @MainActor in
            do {
                // キャラクター一覧取得
                let characters = try await apiRepository.getCharaList()
                self.characters = characters

                // 現在のキャラを取得
                if alarm.charaID.isNotEmpty {
                    let chara = try await apiRepository.fetchCharacter(charaID: alarm.charaID)
                    self.selectedChara = chara

                    // CharaCallを設定
                    self.selectedCharaCall = chara.calls.first { charaCall in
                        charaCall.voiceFileURL.lastPathComponent == alarm.voiceFileName
                    }
                }
            } catch {
                // TODO: キャラクター情報の取得に失敗しました的なアラートを表示
                CharalarmLogger.error("failed to fetch character info, file: \(#file), line: \(#line)", error: error)
            }
        }
    }

    func onDisappear() {
        AudioManagerSingleton.shared.pauseAudio()
    }

    func createOrEditAlarm() {
        switch type {
        case .create:
            createAlarm()
        case .edit:
            editAlarm()
        }
    }

    func deleteAlarm() {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            self.alertMessage = String(localized: "error-failed-to-get-authentication-information")
            self.showingAlert = true
            return
        }
        Task { @MainActor in
            showingIndicator = true
            do {
                let alarmDeleteRequest = AlarmDeleteRequest(alarmID: alarm.alarmID)
                try await apiRepository.deleteAlarm(userID: userID, authToken: authToken, requestBody: alarmDeleteRequest)
                dismissSubject.send()
                showingIndicator = false
            } catch {
                self.alertMessage = String(localized: "alarm-failed-to-delete-the-alarm")
                self.showingAlert = true
            }
        }
    }

    func setRandomChara() {
        selectedChara = nil
        selectedCharaCall = nil
    }

    func setCharaAndCharaCall(chara: Chara, charaCall: CharaCall?) {
        alarm.charaID = chara.charaID
        alarm.charaName = chara.name
        alarm.voiceFileName = charaCall?.voiceFileURL.lastPathComponent ?? ""
        selectedChara = chara
        selectedCharaCall = charaCall
    }

    func showVoiceList(chara: Chara) {
        sheet = .voiceList(chara)
    }

    func updateAlarmName(name: String) {
        alarm.name = name
    }

    func updateAlarmHour(hour: Int) {
        alarm.hour = hour
    }

    func updateAlarmMinute(minute: Int) {
        alarm.minute = minute
    }

    func timeDirrerenceTapped() {
        sheet = .timeDifferenceList
    }

    private func createAlarm() {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            alertMessage = String(localized: "error-failed-to-get-authentication-information")
            showingAlert = true
            return
        }
        guard let userUUID = UUID(uuidString: userID) else {
            alertMessage = String(localized: "error-failed-to-get-authentication-information")
            showingAlert = true
            return
        }
        Task { @MainActor in
            showingIndicator = true
            do {
                let alarmRequest = alarm.toAlarmRequest(userID: userUUID)
                let alarmAddRequest = AlarmAddRequest(alarm: alarmRequest)
                try await apiRepository.addAlarm(userID: userID, authToken: authToken, requestBody: alarmAddRequest)
                dismissSubject.send()
                showingIndicator = false
            } catch {
                CharalarmLogger.error("failed to create alarm, file: \(#file), line: \(#line)", error: error)
                alertMessage = String(localized: "alarm-failed-to-create-an-alarm")
                showingAlert = true
            }
        }
    }

    private func editAlarm() {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            alertMessage = String(localized: "error-failed-to-get-authentication-information")
            showingAlert = true
            return
        }
        guard let userUUID = UUID(uuidString: userID) else {
            alertMessage = String(localized: "error-failed-to-get-authentication-information")
            showingAlert = true
            return
        }
        Task { @MainActor in
            showingIndicator = true
            do {
                let alarmRequest = alarm.toAlarmRequest(userID: userUUID)
                let alarmEditRequest = AlarmEditRequest(alarm: alarmRequest)
                try await apiRepository.editAlarm(userID: userID, authToken: authToken, requestBody: alarmEditRequest)
                dismissSubject.send()
                showingIndicator = false
            } catch {
                alertMessage = String(localized: "alarm-failed-to-edit-the-alarm")
                showingAlert = true
            }
        }
    }
}
