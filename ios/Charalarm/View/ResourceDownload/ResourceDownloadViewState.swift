import Foundation

@MainActor @Observable final class ResourceDownloadViewState {
    private let charaID: String
    /// 「自分のキャラ」として選ぶとき、リソースを入れ終えてから確定する保存
    private let myCharaPending: MyCharaRepository.Pending?
    private let apiRepository = APIRepository()
    private let fileRepository = FileRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let localCharaResourceUseCase = LocalCharaResourceUseCase()

    var mainMessage: String = "リソースをダウンロードしています"
    var progressMessage: String = ""
    var showDismissButton = false

    init(charaID: String, myCharaPending: MyCharaRepository.Pending? = nil) {
        self.charaID = charaID
        self.myCharaPending = myCharaPending
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

                // VRM のキャラは 3D モデルも用意する（同梱していればダウンロードしない）
                if let modelFileURL = chara.modelFileURL {
                    _ = try await VRMModelRepository().modelFileURL(charaID: charaID, modelFileURL: modelFileURL)
                }

                // Chara を CharaLocalResource に変換する
                let localCharaResource = LocalCharaResource(chara: chara)
                try localCharaResourceUseCase.saveCharaResource(charaID: chara.charaID, localCharaResource: localCharaResource)

                mainMessage = "設定完了しました"
                progressMessage = "100%"
                showDismissButton = true

                // キャラを更新する
                if let myCharaPending {
                    try MyCharaRepository().commit(myCharaPending)
                }
                userDefaultsRepository.setCharaDomain(charaDomain: charaID)
                let userInfo: [String: Any] = [
                    NSNotification.setCharaUserInfoKeyCharaID: charaID
                ]
                NotificationCenter.default.post(name: NSNotification.setChara, object: self, userInfo: userInfo)
            } catch {
                // 自分のキャラの保存は確定せず、前のままにする（やり直せるように）
                if let myCharaPending {
                    MyCharaRepository().discard(myCharaPending)
                }
                mainMessage = "ダウンロードに失敗しました"
                showDismissButton = true

            }
        }
    }
}
