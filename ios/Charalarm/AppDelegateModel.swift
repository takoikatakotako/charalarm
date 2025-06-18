import UIKit
import AVKit

class AppDelegateModel {
    private(set) var charaName: String = ""
    private(set) var voiceFileURL: String = ""
    private var audioPlayer = AVAudioPlayer()
    private let apiRepository: APIRepository
    private let fileRepository: FileRepository
    private let keychainRepository: KeychainRepository
    private let userDefaultsRepository: UserDefaultsRepository
    var pushToken: String?
    var voipPushToken: String?

    init(apiRepository: APIRepository, keychainRepository: KeychainRepository) {
        self.apiRepository = APIRepository()
        self.fileRepository = FileRepository()
        self.keychainRepository = KeychainRepository()
        self.userDefaultsRepository = UserDefaultsRepository()
    }

    func setCharaName(charaName: String) {
        self.charaName = charaName
    }

    func setVoiceFileURL(voiceFileURL: String) {
        self.voiceFileURL = voiceFileURL
    }

    func registerDefaults() {
        userDefaultsRepository.registerDefaults()
    }

    // MARK: - Push Notification
    // Pushトークンを登録
    func registerPushToken(token: String) {
        self.pushToken = token
        Variables.shared.setPushToken(token)

        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            return
        }

        Task {
            do {
                let pushTokenRequest = PushTokenRequest(pushToken: token)
                try await apiRepository.postPushTokenAddPushToken(userID: userID, authToken: authToken, pushToken: pushTokenRequest)
            } catch {
                CharalarmLogger.error("Failed to register push token, file: \(#file), line: \(#line)", error: error)
            }
        }
    }

    // VoIPPushトークンを取得できなかった場合
    func failToRregisterPushToken(error: Error) {
        CharalarmLogger.error("Failed to get VoIP token, file: \(#file), line: \(#line)", error: error)
    }

    // MARK: - Voip Push Notification
    // VoIP Pushトークンを登録
    func registerVoipPushToken(token: String) {
        self.voipPushToken = token
        Variables.shared.setVoipPushToken(token)

        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            return
        }

        Task {
            do {
                let pushTokenRequest = PushTokenRequest(pushToken: token)
                try await apiRepository.postPushTokenAddVoIPPushToken(userID: userID, authToken: authToken, pushToken: pushTokenRequest)
            } catch {
                CharalarmLogger.error("Failed to register VoIP push token, file: \(#file), line: \(#line)", error: error)
            }
        }
    }

    // VoIP Pushを受信
    func receiveVoipPush() {
        guard let url = URL(string: voiceFileURL) else {
            // エラーだよメッセージを流す
            return
        }

        // 準備中の音を再生

        Task { @MainActor in
            do {
                let fileData = try await fileRepository.downloadFile(url: url)

                // 準備中の音を停止
                audioPlayer = try AVAudioPlayer(data: fileData)
                audioPlayer.prepareToPlay()
                audioPlayer.play()

            } catch {
                // エラーだよメッセージを流す
            }
        }
    }

    func answerCall(callUUID: UUID) {
        let userInfo: [String: Any] = [
            NSNotification.answerCallUserInfoKeyCharaID: "jp.zunko.zundamon",
            NSNotification.answerCallUserInfoKeyCharaName: charaName,
            NSNotification.answerCallUserInfoKeyCallUUID: callUUID
        ]
        NotificationCenter.default.post(name: NSNotification.answerCall, object: self, userInfo: userInfo)
    }

    func endCall() {
        NotificationCenter.default.post(name: NSNotification.endCall, object: self, userInfo: nil)
    }

    func setEnablePremiumPlan(enable: Bool) {
        guard let userID = keychainRepository.getUserID(), let authToken = keychainRepository.getAuthToken() else {
            return
        }

        Task { @MainActor in
            do {
                userDefaultsRepository.setEnablePremiumPlan(enable: enable)
                let requestBody = UserUpdatePremiumPlanRequest(enablePremiumPlan: enable)
                try await apiRepository.postUserUpdatePremium(userID: userID, authToken: authToken, requestBody: requestBody)
            } catch {
                print(error)
            }
        }
    }
}
