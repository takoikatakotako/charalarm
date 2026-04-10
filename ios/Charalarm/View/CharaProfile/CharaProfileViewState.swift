import Foundation
import CallKit
import SwiftUI

@Observable class CharaProfileViewState {
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
    private var numberOfDownloadedReosurce: Int = 0
    private let apiRepository = APIRepository()
    private let resourceHandler = CharaUseCase()
    private let fileRepository = FileRepository()

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
    }

    init(chara: Chara) {
        charaID = chara.charaID
        self.chara = chara
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
