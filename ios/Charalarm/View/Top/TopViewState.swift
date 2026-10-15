import SwiftUI
import AVFoundation
import AdSupport
import AppTrackingTransparency

enum TopViewModelAlert {
    case failedToGetCharacterInformation
    case failedToGetCharacterSelectionInformation
    case failedToGetCharactersResources
    case failedToSetCharacterImage
    case thisFeatureIsNotAvailableInYourRegion
    case thisCharacterCannotTalkYet

    var message: String {
        switch self {
        case .failedToGetCharacterInformation:
            return String(localized: "error-failed-to-get-character-information")
        case .failedToGetCharacterSelectionInformation:
            return String(localized: "error-failed-to-get-character-selection-information")
        case .failedToGetCharactersResources:
            return String(localized: "error-failed-to-get-characters-resources")
        case .failedToSetCharacterImage:
            return String(localized: "error-failed-to-set-character-image")
        case .thisFeatureIsNotAvailableInYourRegion:
            return String(localized: "error-this-feature-is-not-available-in-your-region")
        case .thisCharacterCannotTalkYet:
            return String(localized: "error-this-character-cannot-talk-yet")
        }
    }
}

enum TopViewModelSheet: Identifiable {
    case newsList
    case characterList
    case alarmList
    case config
    var id: Int {
        return hashValue
    }
}

/// トップに 3D で出すキャラ（見た目が VRM のキャラ）。
struct TopVRMChara: Equatable {
    let charaID: String
    let modelFileURL: URL
}

/// 電話ボタンで通話するキャラ（fullScreenCover 用）。
struct TopConversationChara: Identifiable {
    let charaID: String
    var id: String { charaID }
}

@Observable class TopViewState {
    var charaImage = UIImage()
    /// VRM のキャラを選んでいれば、立ち絵の代わりに 3D で出す
    var vrmChara: TopVRMChara?
    var showingAlert = false
    var alert: TopViewModelAlert? {
        didSet {
            showingAlert = alert != nil
        }
    }
    var sheet: TopViewModelSheet?
    /// 電話ボタンで通話するキャラ。nil でなければ会話画面を出す。
    var conversationChara: TopConversationChara?
    var isPreparingCall = false
    private let userDefaultsRepository: UserDefaultsRepository = UserDefaultsRepository()
    private let fileHandler: FileRepositoryProtocol = FileRepository()

    private let localCharaResourceUseCase = LocalCharaResourceUseCase()
    private let apiRepository = APIRepository()

    var audioPlayer: AVAudioPlayer?

    func onAppear() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        guard let charaID = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            self.alert = .failedToGetCharactersResources
            return
        }
        setVRMChara(charaID: charaID, resource: resource)

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)
    }

    func newsButtonTapped() {
        sheet = .newsList
    }

    func characterListButtonTapped() {
        sheet = .characterList
    }

    func alarmButtonTapped() {
        guard Locale.current.region?.identifier != "CN" else {
            alert = .thisFeatureIsNotAvailableInYourRegion
            return
        }
        sheet = .alarmList
    }

    func configButtonTapped() {
        sheet = .config
    }

    /// タップで会話を始める。会話できると分かっていればすぐ、分からなければサーバに聞いてから
    @MainActor
    private func startConversationIfPossible(charaID: String, knownToTalk: Bool) async {
        guard !isPreparingCall else { return }
        if knownToTalk {
            conversationChara = TopConversationChara(charaID: charaID)
            return
        }
        isPreparingCall = true
        defer { isPreparingCall = false }
        if let chara = try? await apiRepository.fetchCharacter(charaID: charaID), chara.conversation != nil {
            conversationChara = TopConversationChara(charaID: charaID)
        }
    }

    /// 電話ボタン。選んでいるキャラが会話に対応していれば、そのキャラと通話する。
    @MainActor
    func callButtonTapped() async {
        guard !isPreparingCall else { return }
        guard let charaID = userDefaultsRepository.getCharaID() else {
            alert = .failedToGetCharacterSelectionInformation
            return
        }

        isPreparingCall = true
        defer { isPreparingCall = false }
        do {
            let chara = try await apiRepository.fetchCharacter(charaID: charaID)
            guard chara.conversation != nil else {
                alert = .thisCharacterCannotTalkYet
                return
            }
            conversationChara = TopConversationChara(charaID: charaID)
        } catch {
            CharalarmLogger.error("キャラ情報の取得に失敗", error: error)
            alert = .failedToGetCharacterInformation
        }
    }

    /// キャラをタップした。会話できるキャラならお話しを始め、そうでなければタップのボイスを流す
    @MainActor
    func tapped() async {
        guard let charaDomain = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaDomain) else {
            self.alert = .failedToGetCharactersResources
            return
        }

        // 会話できるか分からない (前のバージョンで保存した) ときは、電話ボタンと同じくサーバに聞く
        if resource.hasConversation != false {
            await startConversationIfPossible(charaID: charaDomain, knownToTalk: resource.hasConversation == true)
            if conversationChara != nil || resource.hasConversation == true {
                return
            }
        }

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaDomain, resource: resource, key: key)
        playCharaVoice(charaDomain: charaDomain, resource: resource, key: key)
    }

    func updateChara(charaID: String?) {
        guard let charaID = charaID else {
            DispatchQueue.main.async {
                self.alert = .failedToGetCharacterSelectionInformation
            }
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            DispatchQueue.main.async {
                self.alert = .failedToGetCharactersResources
            }
            return
        }
        setVRMChara(charaID: charaID, resource: resource)

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)
    }

    /// ユーザーが選んだ見た目（なければ既定）が 3D なら 3D で出す。イラストを選んでも画像がなければ 3D にする
    private func setVRMChara(charaID: String, resource: LocalCharaResource) {
        guard let modelFileURL = resource.modelFileURL else {
            vrmChara = nil
            return
        }
        let preferred = userDefaultsRepository.getPreferredAppearance(charaID: charaID)
            ?? resource.defaultAppearance.flatMap(CharaAppearanceKind.init(rawValue:))
        let hasImage = resource.expressions.values.contains { !$0.imageFileNames.isEmpty }
        if preferred == .illustration && hasImage {
            vrmChara = nil
        } else {
            vrmChara = TopVRMChara(charaID: charaID, modelFileURL: modelFileURL)
        }
    }

    private func setCharaImage(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let imageName = resource.expressions[key]?.imageFileNames.randomElement() else {
            return
        }

        do {
            let data = try fileHandler.loadData(directoryName: charaDomain, fileName: imageName)
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.alert = .failedToSetCharacterImage
                }
                return
            }
            charaImage = image
        } catch {
            DispatchQueue.main.async {
                self.alert = .failedToSetCharacterImage
            }
        }
    }

    private func playCharaVoice(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let voiceName = resource.expressions[key]?.voiceFileNames.randomElement() else {
            return
        }

        do {
            let data = try fileHandler.loadData(directoryName: charaDomain, fileName: voiceName)
            audioPlayer = try? AVAudioPlayer(data: data)
            audioPlayer?.play()
        } catch {
            print(error)
        }
    }
}
