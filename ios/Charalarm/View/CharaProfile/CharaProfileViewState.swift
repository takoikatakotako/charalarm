import Foundation
import CallKit
import SwiftUI

@MainActor @Observable final class CharaProfileViewState {
    let charaID: String
    var chara: Chara?
    var showCallView: Bool = false
    var showSelectAlert = false
    var showingResourceDownloadView = false
    var downloadError = false
    var progressMessage = ""
    var showingAlert = false
    var alertMessage = ""

    private var numberOfResource: Int = 0
    private var numberOfDownloadedResource: Int = 0
    private let apiRepository = APIRepository()
    private let resourceHandler = CharaUseCase()
    private let fileRepository = FileRepository()
    private let userDefaultsRepository = UserDefaultsRepository()

    /// ユーザーが選んだ見た目（3D / イラスト）。選んでいなければ nil（既定を使う）
    var preferredAppearance: CharaAppearanceKind?

    /// 表示する見た目
    var selectedAppearance: CharaAppearance? {
        chara?.appearance(preferred: preferredAppearance)
    }

    enum ResourceType: String {
        case image = "image"
        case voice = "voice"
    }

    struct ResourceInfo {
        let type: ResourceType
        let name: String
    }

    var resourceInfos: [ResourceInfo] = []

    var charaThumbnailUrlString: String {
        return resourceHandler.getCharaThumbnailUrlString(charaID: charaID)
    }

    init(charaID: String) {
        self.charaID = charaID
        preferredAppearance = userDefaultsRepository.getPreferredAppearance(charaID: charaID)
    }

    init(chara: Chara) {
        charaID = chara.charaID
        self.chara = chara
        preferredAppearance = userDefaultsRepository.getPreferredAppearance(charaID: charaID)
    }

    /// 見た目を切り替える。今トップに出しているキャラなら、トップも描き直す
    func selectAppearance(kind: CharaAppearanceKind) {
        preferredAppearance = kind
        userDefaultsRepository.setPreferredAppearance(charaID: charaID, kind: kind)
        guard userDefaultsRepository.getCharaID() == charaID else {
            return
        }
        NotificationCenter.default.post(
            name: NSNotification.setChara,
            object: self,
            userInfo: [NSNotification.setCharaUserInfoKeyCharaID: charaID]
        )
    }

    func fetchCharacter() {
        Task { @MainActor in
            do {
                let chara = try await apiRepository.fetchCharacter(charaID: charaID)
                self.chara = chara
            } catch {
                alertMessage = String(localized: "profile-failed-to-get-the-character-information")
                showingAlert = true
            }
        }
    }

    func cancel() {
        resourceInfos = []
        downloadError = false
        showingResourceDownloadView = false
    }

    func close() {
        resourceInfos = []
        downloadError = false
        showingResourceDownloadView = false
    }

    func selectCharacter() {
        Task { @MainActor in
            showingResourceDownloadView = true
        }
    }

    func downloadResource() {
    }

    func setCharacter() {
    }
}
