import Foundation

/// 「自分のキャラ」を端末に保存する。手持ちの VRM は Application Support/MyChara に置き、サーバには送らない
struct MyCharaRepository {
    private static let myCharaKey = "MY_CHARA"
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
    }

    // MARK: - 自分のキャラかどうか

    /// charaID が自分のキャラの土台なら、自分のキャラ。
    /// プリセット（土台）はキャラ一覧に出ないので、土台の ID は自分のキャラを選んだときにしか使われない。
    /// ホームで選んでいるキャラに関係なく決まるので、自分のキャラにしたアラームの電話でも自分のキャラとして出せる
    func myChara(charaID: String) -> MyChara? {
        guard let myChara = load(), myChara.baseCharaID == charaID else { return nil }
        return myChara
    }

    /// ホームで自分のキャラを選んでいるか
    var isSelected: Bool {
        guard let charaID = UserDefaultsRepository().getCharaID() else { return false }
        return myChara(charaID: charaID) != nil
    }

    // MARK: - 保存を確定する

    /// 保存の中身。土台を変えるときは、土台のリソースを入れ終えてから確定する（失敗したら捨てて、前のままにする）
    struct Pending {
        let myChara: MyChara
        /// 前に使っていた手持ちの VRM（確定したら消す）
        let previousVRMFileName: String?
    }

    func commit(_ pending: Pending) throws {
        try save(pending.myChara)
        if let old = pending.previousVRMFileName, old != pending.myChara.importedVRMFileName {
            removeVRM(fileName: old)
        }
    }

    /// 確定しなかった保存を捨てる（このために書いた手持ちの VRM を消す）
    func discard(_ pending: Pending) {
        if let fileName = pending.myChara.importedVRMFileName, fileName != pending.previousVRMFileName {
            removeVRM(fileName: fileName)
        }
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
