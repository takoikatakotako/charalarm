import Foundation
import AVFoundation

/// 「自分のキャラ」を作る・直す画面
@MainActor @Observable final class MyCharaViewState {
    enum Alert: Identifiable {
        case notVRM
        case tooLarge
        case readFailed
        case saveFailed
        case presetsFailed
        case inUse
        case voiceFailed

        var id: Self { self }

        var message: String {
            switch self {
            case .notVRM: return String(localized: "my-chara-error-not-vrm")
            case .tooLarge: return String(localized: "my-chara-error-too-large")
            case .readFailed: return String(localized: "my-chara-error-read")
            case .saveFailed: return String(localized: "my-chara-error-save")
            case .presetsFailed: return String(localized: "common-failed-to-connect-with-the-server")
            case .inUse: return String(localized: "my-chara-delete-in-use")
            case .voiceFailed: return String(localized: "my-chara-error-voice")
            }
        }
    }

    /// 土台にできるプリセットのキャラ
    private(set) var presets: [Chara] = []
    private(set) var isLoadingPresets = true
    var selectedPresetID: String?
    var name = ""
    var personality = ""
    var selectedVoiceID: String?
    private(set) var voices: [CharaVoice] = []
    private(set) var isLoadingVoices = true
    private(set) var isPreviewingVoice = false
    private var voicePlayer: AVAudioPlayer?
    private var voicePreviewTask: Task<Void, Never>?
    private var voicePreviewID = UUID()
    private var hasAppeared = false
    /// 手持ちの VRM を使うか
    var usesImportedVRM = false
    /// 読み込んだ VRM（まだ保存していないもの）
    private var pendingVRMData: Data?
    /// 保存してある手持ちの VRM
    private(set) var savedVRMFileName: String?
    /// プレビューに出す、読み込んだ VRM（保存前は一時ファイル）
    private(set) var importedPreviewURL: URL?
    private(set) var importedTitle: String?

    var alert: Alert?
    var showingImporter = false
    /// アバターとして使える人が限られた VRM を読み込もうとしている（確かめてから使う）
    var licenseConfirmation: Data?
    var showingResourceDownloadView = false
    private(set) var hasMyChara = false

    private let repository = MyCharaRepository()
    private let apiRepository = APIRepository()

    var selectedPreset: Chara? {
        presets.first { $0.charaID == selectedPresetID }
    }

    /// プレビューに出す VRM
    var previewModelFileURL: URL? {
        if usesImportedVRM, let importedPreviewURL {
            return importedPreviewURL
        }
        return selectedPreset?.modelFileURL
    }

    /// プレビューに出す立ち絵（3D の見た目がないプリセットのとき）
    var previewImageURL: URL? {
        guard previewModelFileURL == nil, let preset = selectedPreset else { return nil }
        let expressions = preset.expressions
        return (expressions["normal"] ?? expressions.values.first)?.imageFileURLs.first
            ?? URL(string: preset.thumbnailUrlString)
    }

    var canSave: Bool {
        selectedPreset != nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && name.unicodeScalars.count <= 50 && personality.unicodeScalars.count <= 1000
            && (hasMyChara || selectedVoiceID != nil)
            && (!usesImportedVRM || importedPreviewURL != nil)
    }

    func onAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        if let myChara = repository.load() {
            hasMyChara = true
            selectedPresetID = myChara.baseCharaID
            name = myChara.name
            personality = myChara.personality ?? ""
            selectedVoiceID = myChara.voiceID
            savedVRMFileName = myChara.importedVRMFileName
            usesImportedVRM = myChara.importedVRMFileName != nil
            importedPreviewURL = repository.modelFileURL(of: myChara).flatMap { $0.isFileURL ? $0 : nil }
        }
        Task {
            do {
                presets = try await apiRepository.fetchPresets()
                if selectedPresetID == nil {
                    selectedPresetID = presets.first?.charaID
                }
            } catch {
                CharalarmLogger.error("プリセットのキャラを取れませんでした", error: error)
                alert = .presetsFailed
            }
            isLoadingPresets = false
        }
        Task {
            await loadVoices()
        }
    }

    func loadVoices() async {
        isLoadingVoices = true
        defer { isLoadingVoices = false }
        do {
            voices = try await apiRepository.fetchCharaVoices()
            if !hasMyChara && selectedVoiceID == nil {
                selectedVoiceID = voices.first?.id
            }
        } catch {
            alert = .presetsFailed
        }
    }

    func previewVoice() {
        stopVoicePreview()
        guard let selectedVoiceID, !baseCharaID.isEmpty else { return }
        let charaID = baseCharaID
        let previewID = voicePreviewID
        isPreviewingVoice = true
        voicePreviewTask = Task {
            defer {
                if voicePreviewID == previewID { isPreviewingVoice = false }
            }
            do {
                let keychain = KeychainRepository()
                guard let userID = keychain.getUserID(), let token = keychain.getAuthToken() else {
                    throw ConversationError.notAuthenticated
                }
                let data = try await apiRepository.postTextToSpeech(
                    userID: userID, authToken: token, charaID: charaID,
                    text: String(localized: "my-chara-voice-sample"), voiceID: selectedVoiceID
                )
                try Task.checkCancellation()
                voicePlayer = try AVAudioPlayer(data: data)
                voicePlayer?.play()
            } catch where Task.isCancelled {
                // The user changed voice or left the screen.
            } catch {
                alert = .voiceFailed
            }
        }
    }

    func stopVoicePreview() {
        voicePreviewID = UUID()
        voicePreviewTask?.cancel()
        voicePreviewTask = nil
        voicePlayer?.stop()
        voicePlayer = nil
        isPreviewingVoice = false
    }

    // MARK: - 手持ちの VRM

    func importVRM(result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            alert = .readFailed
            return
        }
        Task {
            switch await Self.readVRMFile(url) {
            case .success(let data):
                inspectImported(data)
            case .failure(let error):
                alert = error == .tooLarge ? .tooLarge : .readFailed
            }
        }
    }

    private enum ReadError: Error {
        case tooLarge
        case unreadable
    }

    /// 大きすぎるファイルを読み込まないよう、先に大きさを見る。読み込みは画面を止めないよう別のスレッドで
    nonisolated private static func readVRMFile(_ url: URL) async -> Result<Data, ReadError> {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return .failure(.unreadable)
        }
        guard size <= VRMFileInspector.maxFileSize else {
            return .failure(.tooLarge)
        }
        guard let data = try? Data(contentsOf: url) else {
            return .failure(.unreadable)
        }
        return .success(data)
    }

    private func inspectImported(_ data: Data) {
        do {
            let inspection = try VRMFileInspector.inspect(data)
            if inspection.avatarPermission == .everyone {
                useImported(data, title: inspection.title)
            } else {
                licenseConfirmation = data
            }
        } catch VRMFileInspector.InspectionError.tooLarge {
            alert = .tooLarge
        } catch {
            alert = .notVRM
        }
    }

    /// 利用条件を確かめたうえで使う
    func confirmLicense() {
        guard let data = licenseConfirmation else { return }
        licenseConfirmation = nil
        useImported(data, title: try? VRMFileInspector.inspect(data).title)
    }

    private func useImported(_ data: Data, title: String?) {
        let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent("my-chara-\(UUID().uuidString).vrm")
        do {
            try data.write(to: previewURL, options: .atomic)
        } catch {
            alert = .readFailed
            return
        }
        pendingVRMData = data
        importedPreviewURL = previewURL
        importedTitle = title
        usesImportedVRM = true
    }

    // MARK: - 保存・選ぶ・消す

    /// 「このキャラにする」のダウンロードで、入れ終えたら確定する保存
    private(set) var pendingSelection: MyCharaRepository.Pending?

    /// ホームで使っているあいだに、もとにするキャラを変えた（保存は、そのキャラのリソースを入れ終えてから確定する）
    var needsReselect: Bool {
        repository.isSelected && repository.load()?.baseCharaID != selectedPresetID
    }

    /// ツールバーの「保存」。使っているあいだに土台を変えたときは、ダウンロードを出して選び直す（閉じない）
    func saveFromToolbar() -> Bool {
        if needsReselect {
            startSelection()
            return false
        }
        return save()
    }

    /// すぐに確定する保存（ホームで使っている土台を変えないとき）
    @discardableResult
    func save() -> Bool {
        guard let pending = makePending() else { return false }
        do {
            try repository.commit(pending)
            didCommit(pending.myChara)
            notifyIfSelected(pending.myChara)
            return true
        } catch {
            repository.discard(pending)
            CharalarmLogger.error("自分のキャラを保存できませんでした", error: error)
            alert = .saveFailed
            return false
        }
    }

    /// このキャラにする。土台のキャラのボイスなどを入れ終えてから保存を確定する（失敗したら前のまま）
    func select() {
        startSelection()
    }

    private func startSelection() {
        guard let pending = makePending() else { return }
        pendingSelection = pending
        showingResourceDownloadView = true
    }

    /// ダウンロードの画面を閉じた。確定していれば、保存した状態に合わせる（失敗していれば、やり直せるよう今の入力のまま）
    func selectionFinished() {
        pendingSelection = nil
        guard let saved = repository.load() else { return }
        hasMyChara = true
        if saved.importedVRMFileName != savedVRMFileName {
            didCommit(saved)
        }
    }

    var downloadCharaID: String {
        pendingSelection?.myChara.baseCharaID ?? baseCharaID
    }

    /// 保存する中身を作る。手持ちの VRM はここでファイルに書く（確定しなければ捨てる）
    private func makePending() -> MyCharaRepository.Pending? {
        guard let preset = selectedPreset, canSave else { return nil }
        do {
            var fileName = usesImportedVRM ? savedVRMFileName : nil
            if usesImportedVRM, let pendingVRMData {
                fileName = try repository.saveVRM(pendingVRMData)
            }
            let myChara = MyChara(
                baseCharaID: preset.charaID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                importedVRMFileName: fileName,
                presetModelFileURL: preset.modelFileURL,
                personality: personality.trimmingCharacters(in: .whitespacesAndNewlines),
                voiceID: selectedVoiceID
            )
            return MyCharaRepository.Pending(myChara: myChara, previousVRMFileName: savedVRMFileName)
        } catch {
            CharalarmLogger.error("自分のキャラの VRM を保存できませんでした", error: error)
            alert = .saveFailed
            return nil
        }
    }

    private func didCommit(_ myChara: MyChara) {
        pendingVRMData = nil
        savedVRMFileName = myChara.importedVRMFileName
        hasMyChara = true
    }

    var baseCharaID: String {
        selectedPresetID ?? ""
    }

    func delete() -> Bool {
        guard !repository.isSelected else {
            alert = .inUse
            return false
        }
        repository.delete()
        return true
    }

    /// ホームで使っているあいだに直したら、トップに出し直させる
    private func notifyIfSelected(_ myChara: MyChara) {
        guard repository.isSelected else { return }
        NotificationCenter.default.post(
            name: NSNotification.setChara,
            object: self,
            userInfo: [NSNotification.setCharaUserInfoKeyCharaID: myChara.baseCharaID]
        )
    }
}
