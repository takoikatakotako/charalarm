import Foundation

/// 「自分のキャラ」を端末に保存する。手持ちの VRM は Application Support/MyChara に置き、サーバには送らない
struct MyCharaRepository {
    private static let myCharaKey = "MY_CHARA"
    private static let activeKey = "MY_CHARA_ACTIVE"
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default

    func load() -> MyChara? {
        guard let data = defaults.data(forKey: Self.myCharaKey) else { return nil }
        return try? JSONDecoder().decode(MyChara.self, from: data)
    }

    func save(_ myChara: MyChara) throws {
        defaults.set(try JSONEncoder().encode(myChara), forKey: Self.myCharaKey)
    }

    /// 自分のキャラと、手持ちの VRM を消す
    func delete() {
        if let fileName = load()?.importedVRMFileName, let url = try? vrmFileURL(fileName: fileName) {
            try? fileManager.removeItem(at: url)
        }
        defaults.removeObject(forKey: Self.myCharaKey)
        defaults.removeObject(forKey: Self.activeKey)
    }

    // MARK: - 選んでいるか

    /// 自分のキャラを選んでいるか（キャラの選択は土台のキャラの ID で持ち、この印で自分のキャラとして見せる）
    var isActive: Bool {
        defaults.bool(forKey: Self.activeKey) && load() != nil
    }

    func setActive(_ active: Bool) {
        defaults.set(active, forKey: Self.activeKey)
    }

    /// charaID のキャラを自分のキャラとして見せるときの自分のキャラ。選んでいなければ nil
    func activeMyChara(charaID: String) -> MyChara? {
        guard isActive, let myChara = load(), myChara.baseCharaID == charaID else { return nil }
        return myChara
    }

    /// 自分のキャラの見た目（VRM）。手持ちの VRM があればそのファイル、なければ土台のキャラの VRM
    func modelFileURL(of myChara: MyChara) -> URL? {
        if let fileName = myChara.importedVRMFileName {
            return try? vrmFileURL(fileName: fileName)
        }
        return myChara.presetModelFileURL
    }

    // MARK: - 手持ちの VRM

    /// 読み込んだ VRM を保存し、ファイル名を返す。差し替えのたびに別の名前にする（表示を作り直させるため）
    func saveVRM(_ data: Data) throws -> String {
        let fileName = "\(UUID().uuidString).vrm"
        let url = try vrmFileURL(fileName: fileName)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return fileName
    }

    func removeVRM(fileName: String) {
        if let url = try? vrmFileURL(fileName: fileName) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func vrmFileURL(fileName: String) throws -> URL {
        guard let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw FileHandlerError.directoryNotFound
        }
        return directory
            .appendingPathComponent("MyChara", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
