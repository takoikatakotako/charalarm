import SwiftUI
import FirebaseAuth

@Observable class RootViewState {
    var type: RootViewType = .loading

    var charaID: String?
    var charaName: String?
    var callUUID: UUID?

    private let apiRepository = APIRepository()
    private let appUseCase = AppUseCase()
    private let charaUseCase = CharaUseCase()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let fileRepository: FileRepositoryProtocol = FileRepository()

    func onAppear() {
        Task { @MainActor in
            do {
                // ローディング中（初回起動）のみ先に進む
                guard type == .loading else {
                    return
                }

                // TODO: ネットワークチェック

                // メンテナンス中か確認
                let isMaintenance = try await apiRepository.fetchMaintenance()
                if isMaintenance {
                    withAnimation(.linear(duration: 1)) {
                        type = .maintenance
                    }
                    return
                }

                // アップデートが必要か確認
                let requireVersion = try await apiRepository.fetchRequireVersion()
                if requireVersion > appUseCase.appVersion {
                    withAnimation(.linear(duration: 1)) {
                        type = .updateRequire
                    }
                    return
                }

                // Firebaseログイン
                try await Auth.auth().signInAnonymously()

                // UserDefaults に初期値を入れる
                userDefaultsRepository.registerDefaults()

                // 初期ファイルが配置済みか確認する
                let exists: Bool = charaUseCase.isExistDefaultCharaResources()
                if exists == false {
                    try charaUseCase.copyToDefaultCharaDirectory()
                }

                // デコードできるかチェックする
                if let localCharaResource = try? charaUseCase.loadLocalCharaResource() {
                    // 最新更新できるかチェックする
                    try? await charaUseCase.checkUpdateCharaResource(charaID: localCharaResource.charaID, updatedAt: localCharaResource.updatedAt)
                } else {
                    // 最新版を落とす
                    try? await charaUseCase.fetchAndDownloadCharaResource()
                }

                // チュートリアルの状態を確認
                if appUseCase.isDoneTutorial {
                    withAnimation(.linear(duration: 1)) {
                        type = .top
                    }
                } else {
                    withAnimation(.linear(duration: 1)) {
                        type = .tutorial
                    }
                }
            } catch {
                print(error)
                withAnimation(.linear(duration: 1)) {
                    type = .error
                }
            }
        }
    }

    func doneTutorial() {
        withAnimation(.linear(duration: 1)) {
            type = .top
        }
    }

    func didReset() {
        withAnimation(.linear(duration: 1)) {
            type = .tutorial
        }
    }

    func answerCall(charaID: String?, charaName: String?, callUUID: UUID?) {
        self.charaID = charaID
        self.charaName = charaName
        self.callUUID = callUUID
        // 会話対応キャラ（ずんだもん）は音声会話画面へ、それ以外は従来の録音再生へ
        type = ConversationCapability.isCapable(charaID: charaID) ? .conversation : .calling
    }

    func endCall() {
        withAnimation(.linear(duration: 1)) {
            type = .top
        }
    }
}
