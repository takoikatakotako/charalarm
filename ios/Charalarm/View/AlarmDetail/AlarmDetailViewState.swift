import Foundation
import SwiftUI

@MainActor @Observable final class AlarmDetailViewState {
    var alarm: Alarm
    var characters: [Chara] = []
    var showingAlert = false
    var alertMessage = ""
    var sheet: AlarmDetailViewSheetItem?
    var selectedChara: Chara?
    var selectedCharaCall: CharaCall?
    var showingIndicator: Bool = false
    /// true にすると画面を閉じる（保存・削除が終わったとき）
    var shouldDismiss = false
    /// 電話（AI 会話）の設定。アラームと一緒に保存する。設定の無い古いアラームは、アプリ共通の設定から始める
    var callSettings: CallSettings

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
        self.callSettings = alarm.call ?? .appDefault
    }

    /// 天気の地域を設定で選んでいるか（選んでいなければ天気は話せない）
    var hasWeatherRegion: Bool {
        UserDefaultsRepository().getWeatherRegion() != nil
    }

    /// 電話の最初に今日の予定を話す。オンにするときにカレンダーの許可を求める
    func setCallSchedule(_ schedule: Bool) {
        guard schedule else {
            callSettings.schedule = false
            return
        }
        Task { @MainActor in
            let granted = await CalendarRepository().requestAccess()
            callSettings.schedule = granted
            if !granted {
                alertMessage = String(localized: "config-calendar-access-denied")
                showingAlert = true
            }
        }
    }

    func onAppear() {
        Task { @MainActor in
            do {
                // キャラクター一覧取得。自分のキャラがあれば先頭に足す（一覧の API にはプリセットが出ないため、土台のキャラを取る）
                var characters = try await apiRepository.getCharaList()
                let myChara = MyCharaRepository().load()
                if let myChara, var base = try? await apiRepository.fetchCharacter(charaID: myChara.baseCharaID) {
                    base.name = myChara.name
                    characters.insert(base, at: 0)
                }
                self.characters = characters

                // 現在のキャラを取得
                if alarm.charaID.isNotEmpty {
                    var chara = try await apiRepository.fetchCharacter(charaID: alarm.charaID)
                    if let myChara, myChara.baseCharaID == chara.charaID {
                        chara.name = myChara.name
                    }
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
                shouldDismiss = true
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
                alarm.call = callSettings
                let alarmRequest = alarm.toAlarmRequest(userID: userUUID)
                let alarmAddRequest = AlarmAddRequest(alarm: alarmRequest)
                try await apiRepository.addAlarm(userID: userID, authToken: authToken, requestBody: alarmAddRequest)
                shouldDismiss = true
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
                alarm.call = callSettings
                let alarmRequest = alarm.toAlarmRequest(userID: userUUID)
                let alarmEditRequest = AlarmEditRequest(alarm: alarmRequest)
                try await apiRepository.editAlarm(userID: userID, authToken: authToken, requestBody: alarmEditRequest)
                shouldDismiss = true
                showingIndicator = false
            } catch {
                alertMessage = String(localized: "alarm-failed-to-edit-the-alarm")
                showingAlert = true
            }
        }
    }
}
