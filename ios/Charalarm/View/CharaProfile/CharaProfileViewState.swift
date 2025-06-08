import Foundation
import CallKit
import SwiftUI
import Combine

class CharaProfileViewState: ObservableObject {
    let charaID: String
    @Published var chara: Chara?
    @Published var showCallView: Bool = false
    @Published var showSelectAlert = false
    @Published var showingResourceDownloadView = false
    @Published var downloadError = false
    @Published var progressMessage = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""

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

//            guard let chara = chara else {
//                // 読み込み中です的なやつ表示
//                return
//            }
//

//            let result = try await ResourceStore.downloadResourceJson(charaDomain: charaDomain)
//            switch result {
//            case let .success(resource):
//                self.numberOfResource = resource.resource.images.count + resource.resource.voices.count
//                self.numberOfDownloadedReosurce = 0
//
//                DispatchQueue.main.async {
//                    self.progressMessage = "\(String(self.numberOfDownloadedReosurce))/\(String(self.numberOfResource))"
//                }
//
//                self.resourceInfos = []
//                for image in resource.resource.images {
//                    self.resourceInfos.append(ResourceInfo(type: .image, name: image))
//                }
//
//                for voice in resource.resource.voices {
//                    self.resourceInfos.append(ResourceInfo(type: .voice, name: voice))
//                }
//
//                self.downloadResource()
//
//            case .failure:
//                self.downloadError = true
//            }
//
//            showingDownloadingModal = true
        }
    }

    func downloadResource() {
//        guard let resourceInfo = resourceInfos.first else {
//            self.numberOfDownloadedReosurce = 0
//            self.numberOfResource = 0
//            DispatchQueue.main.async {
//                self.showingDownloadingModal = false
//                self.setCharacter()
//            }
//            return
//        }

//        ResourceStore.downloadResource(charaDomain: charaDomain, directory: resourceInfo.type.rawValue, fileName: resourceInfo.name) {[weak self] result in
//            switch result {
//            case .success(_):
//                if self?.resourceInfos.isEmpty ?? true {
//                    return
//                }
//                self?.resourceInfos.removeFirst()
//                self?.numberOfDownloadedReosurce += 1
//                DispatchQueue.main.async {
//                    self?.progressMessage = "\(String(self?.numberOfDownloadedReosurce ?? 0))/\(String(self?.numberOfResource ?? 0))"
//                }
//                self?.downloadResource()
//            case .failure(_):
//                DispatchQueue.main.async {
//                    self?.showingDownloadingModal = false
//                    self?.alertMessage = R.string.localizable.profileFailedToDownloadResources()
//                    self?.showingAlert = true
//                }
//            }
//        }
    }

    func setCharacter() {
//        guard
//            let charaDomain = character?.charaDomain,
//            let charaName = character?.name else {
//            return
//        }
//        
//        charalarmEnvironment.userDefaultsHandler.setCharaDomain(charaDomain: charaDomain)
//        charalarmEnvironment.userDefaultsHandler.setCharaName(charaName: charaName)
//        NotificationCenter.default.post(name: NSNotification.setChara, object: nil, userInfo: nil)
    }
}
