import Foundation

/// 「自分のキャラ」を作る・直す画面
@MainActor @Observable final class MyCharaViewState {
    enum Alert: Identifiable {
        case notVRM
        case tooLarge
        case readFailed
        case saveFailed
        case presetsFailed
        case inUse

        var id: Self { self }

        var message: String {
            switch self {
            case .notVRM: return String(localized: "my-chara-error-not-vrm")
            case .tooLarge: return String(localized: "my-chara-error-too-large")
            case .readFailed: return String(localized: "my-chara-error-read")
            case .saveFailed: return String(localized: "my-chara-error-save")
            case .presetsFailed: return String(localized: "common-failed-to-connect-with-the-server")
            case .inUse: return String(localized: "my-chara-delete-in-use")
            }
        }
    }

    /// 土台にできるプリセットのキャラ
    private(set) var presets: [Chara] = []
    private(set) var isLoadingPresets = true
    var selectedPresetID: String?
    var name = ""
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
    private(set) var isActive = false

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

    var canSave: Bool {
        selectedPreset != nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!usesImportedVRM || importedPreviewURL != nil)
    }

    func onAppear() {
        if let myChara = repository.load() {
            hasMyChara = true
            selectedPresetID = myChara.baseCharaID
            name = myChara.name
            savedVRMFileName = myChara.importedVRMFileName
            usesImportedVRM = myChara.importedVRMFileName != nil
            importedPreviewURL = repository.modelFileURL(of: myChara).flatMap { $0.isFileURL ? $0 : nil }
        }
        isActive = repository.isActive
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
    }

    // MARK: - 手持ちの VRM

    func importVRM(result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            alert = .readFailed
            return
        }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            alert = .readFailed
            return
        }
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

    @discardableResult
    func save() -> Bool {
        guard let preset = selectedPreset, canSave else { return false }
        do {
            var fileName = usesImportedVRM ? savedVRMFileName : nil
            if usesImportedVRM, let pendingVRMData {
                fileName = try repository.saveVRM(pendingVRMData)
            }
            // 使わなくなった手持ちの VRM は消す
            if let old = savedVRMFileName, old != fileName {
                repository.removeVRM(fileName: old)
            }
            let myChara = MyChara(
                baseCharaID: preset.charaID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                importedVRMFileName: fileName,
                presetModelFileURL: preset.modelFileURL
            )
            try repository.save(myChara)
            pendingVRMData = nil
            savedVRMFileName = fileName
            hasMyChara = true
            notifyIfActive(myChara)
            return true
        } catch {
            CharalarmLogger.error("自分のキャラを保存できませんでした", error: error)
            alert = .saveFailed
            return false
        }
    }

    /// 保存して、このキャラにする（土台のキャラのボイスなどをダウンロードする）
    func select() {
        guard save() else { return }
        showingResourceDownloadView = true
    }

    var baseCharaID: String {
        selectedPresetID ?? ""
    }

    func delete() -> Bool {
        guard !repository.isActive else {
            alert = .inUse
            return false
        }
        repository.delete()
        return true
    }

    /// 使っているあいだに直したら、トップに出し直させる
    private func notifyIfActive(_ myChara: MyChara) {
        guard repository.isActive else { return }
        NotificationCenter.default.post(
            name: NSNotification.setChara,
            object: self,
            userInfo: [NSNotification.setCharaUserInfoKeyCharaID: myChara.baseCharaID]
        )
    }
}
