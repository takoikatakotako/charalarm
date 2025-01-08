import Foundation

class ResourceDownloadViewState: ObservableObject {
    private let charaID: String
    private let apiRepository = APIRepository()
    private let fileRepository = FileRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let localCharaResourceUseCase = LocalCharaResourceUseCase()

    @Published var mainMessage: String = "リソースをダウンロードしています"
    @Published var progressMessage: String = ""
    @Published var showDismissButton = false

    init(charaID: String) {
        self.charaID = charaID
    }

    func onAppear() {
        Task { @MainActor in
            do {
                let chara = try await apiRepository.fetchCharacter(charaID: charaID)
                for (index, resource) in chara.resources.enumerated() {
                    let progressPercent = Int(round(Float(index + 1) / Float(chara.resources.count) * 100))
                    progressMessage = "\(progressPercent)%"

                    let fileName = resource.fileURL.lastPathComponent
                    let fileData = try await fileRepository.downloadFile(url: resource.fileURL)
                    try fileRepository.saveFile(directoryName: charaID, fileName: fileName, data: fileData)
                }

                // Chara を CharaLocalResource に変換する
                let localCharaResource = LocalCharaResource(chara: chara)
                try localCharaResourceUseCase.saveCharaResource(charaID: chara.charaID, localCharaResource: localCharaResource)

                mainMessage = "設定完了しました"
                progressMessage = "100%"
                showDismissButton = true

                // キャラを更新する
                userDefaultsRepository.setCharaDomain(charaDomain: charaID)
                let userInfo: [String: Any] = [
                    NSNotification.setCharaUserInfoKeyCharaID: charaID
                ]
                NotificationCenter.default.post(name: NSNotification.setChara, object: self, userInfo: userInfo)
            } catch {
                mainMessage = "ダウンロードに失敗しました"
                showDismissButton = true

            }
        }
    }
}
