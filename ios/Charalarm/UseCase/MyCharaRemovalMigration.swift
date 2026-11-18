import Foundation

/// 廃止した「自分のキャラ」の端末データを削除する。アラームの移行に失敗した場合は次回起動で再試行する。
struct MyCharaRemovalMigration {
    static let fallbackCharaID = "com.charalarm.yui"
    static let fallbackCharaName = "井上結衣"

    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let applicationSupport: URL
    private let documents: URL
    private let caches: URL
    private let retiredIDKey = "REMOVED_MY_CHARA_BASE_ID"
    private let completedKey = "MY_CHARA_ALARM_MIGRATION_COMPLETED"

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default,
         applicationSupport: URL? = nil, documents: URL? = nil, caches: URL? = nil) {
        self.defaults = defaults
        self.fileManager = fileManager
        self.applicationSupport = applicationSupport ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.documents = documents ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.caches = caches ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    // 保存したキャラを旧アプリで既に削除していても、アラームだけ残っている場合がある。
    var hasPendingAlarms: Bool { !defaults.bool(forKey: completedKey) }

    func isRetiredCharaID(_ charaID: String) -> Bool {
        charaID.hasPrefix("com.charalarm.preset.")
            || charaID == defaults.string(forKey: retiredIDKey)
            || charaID == savedBaseCharaID
    }

    func removeSavedData() throws {
        if defaults.object(forKey: "MY_CHARA") != nil {
            if let baseCharaID = savedBaseCharaID {
                defaults.set(baseCharaID, forKey: retiredIDKey)
            }
            defaults.set(false, forKey: completedKey)
        }
        if let selectedID = defaults.string(forKey: "CHARA_DOMAIN"), isRetiredCharaID(selectedID) {
            defaults.set(Self.fallbackCharaID, forKey: "CHARA_DOMAIN")
            defaults.set(Self.fallbackCharaName, forKey: "CHARA_NAME")
            defaults.set(false, forKey: completedKey)
        }
        defaults.removeObject(forKey: "MY_CHARA")
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("PREFERRED_APPEARANCE_") {
            if isRetiredCharaID(String(key.dropFirst("PREFERRED_APPEARANCE_".count))) {
                defaults.removeObject(forKey: key)
            }
        }

        // 保存ファイル名を信用せず、機能専用のディレクトリとプリセットのキャッシュだけを消す。
        let importedModels = applicationSupport.appendingPathComponent("MyChara", isDirectory: true)
        if fileManager.fileExists(atPath: importedModels.path) {
            try fileManager.removeItem(at: importedModels)
        }
        for parent in [documents, caches.appendingPathComponent("vrm", isDirectory: true)] {
            guard fileManager.fileExists(atPath: parent.path) else { continue }
            for directory in try fileManager.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)
                where isRetiredCharaID(directory.lastPathComponent) {
                try fileManager.removeItem(at: directory)
            }
        }
    }

    func finishAlarmMigration() {
        defaults.set(true, forKey: completedKey)
    }

    private var savedBaseCharaID: String? {
        struct LegacyCharacter: Decodable { let baseCharaID: String }
        guard let data = defaults.data(forKey: "MY_CHARA") else { return nil }
        return (try? JSONDecoder().decode(LegacyCharacter.self, from: data))?.baseCharaID
    }
}
