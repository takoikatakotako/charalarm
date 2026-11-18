import Foundation

// swiftc -parse-as-library Charalarm/UseCase/MyCharaRemovalMigration.swift scripts/tests/my-chara-removal.swift -o /tmp/my-chara-removal
@main
enum MyCharaRemovalChecks {
    static func main() throws {
        let suite = "MyCharaRemovalChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let manager = FileManager.default
        let directory = manager.temporaryDirectory.appendingPathComponent(suite)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? manager.removeItem(at: directory)
        }
        let support = directory.appendingPathComponent("support")
        let documents = directory.appendingPathComponent("documents")
        let caches = directory.appendingPathComponent("caches")
        let migration = MyCharaRemovalMigration(defaults: defaults, applicationSupport: support, documents: documents, caches: caches)
        // 端末に保存レコードがなくても、サーバのアラームを一度は確認する。
        precondition(migration.hasPendingAlarms)
        let presetID = "com.charalarm.preset.hinata"
        let folders = [support.appendingPathComponent("MyChara"), documents.appendingPathComponent(presetID),
                       caches.appendingPathComponent("vrm/\(presetID)"), documents.appendingPathComponent("com.charalarm.yui")]
        for folder in folders {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data("preserved or removed".utf8).write(to: folder.appendingPathComponent("test.dat"))
        }
        defaults.set(Data(#"{"baseCharaID":"com.charalarm.preset.hinata","name":"旧キャラ","personality":"秘密","voiceID":"Charon","importedVRMFileName":"../../other.vrm"}"#.utf8), forKey: "MY_CHARA")
        defaults.set(presetID, forKey: "CHARA_DOMAIN")
        defaults.set("旧キャラ", forKey: "CHARA_NAME")
        defaults.set("illustration", forKey: "PREFERRED_APPEARANCE_\(presetID)")
        defaults.set("vrm", forKey: "PREFERRED_APPEARANCE_com.charalarm.yui")
        defaults.set(true, forKey: "ENABLE_PREMIUM_PLAN")
        try migration.removeSavedData()
        precondition(defaults.object(forKey: "MY_CHARA") == nil)
        precondition(defaults.string(forKey: "CHARA_DOMAIN") == MyCharaRemovalMigration.fallbackCharaID)
        precondition(defaults.string(forKey: "CHARA_NAME") == MyCharaRemovalMigration.fallbackCharaName)
        precondition(defaults.object(forKey: "PREFERRED_APPEARANCE_\(presetID)") == nil)
        precondition(defaults.string(forKey: "PREFERRED_APPEARANCE_com.charalarm.yui") == "vrm")
        precondition(defaults.bool(forKey: "ENABLE_PREMIUM_PLAN"))
        precondition(migration.hasPendingAlarms)
        for folder in folders.dropLast() { precondition(!manager.fileExists(atPath: folder.path)) }
        precondition(manager.fileExists(atPath: folders.last!.appendingPathComponent("test.dat").path))

        // オフラインなどで移行が未完了なら、再起動しても再試行の印を残す。
        try migration.removeSavedData()
        precondition(migration.hasPendingAlarms)
        migration.finishAlarmMigration()
        defaults.set("jp.zunko.zundamon", forKey: "CHARA_DOMAIN")
        defaults.set("ずんだもん", forKey: "CHARA_NAME")
        try migration.removeSavedData()
        precondition(!migration.hasPendingAlarms)
        precondition(defaults.string(forKey: "CHARA_DOMAIN") == "jp.zunko.zundamon")
        precondition(defaults.string(forKey: "CHARA_NAME") == "ずんだもん")

        // 壊れた JSON でも消去し、選択中のプリセットを通常キャラに戻す。
        defaults.set(Data("broken".utf8), forKey: "MY_CHARA")
        defaults.set("com.charalarm.preset.ren", forKey: "CHARA_DOMAIN")
        try migration.removeSavedData()
        precondition(defaults.object(forKey: "MY_CHARA") == nil)
        precondition(defaults.string(forKey: "CHARA_DOMAIN") == MyCharaRemovalMigration.fallbackCharaID)
        precondition(migration.hasPendingAlarms)

        // 古いプリセットの ID 形式も、アラームの移行に必要な ID だけ残して識別する。
        defaults.set(Data(#"{"baseCharaID":"legacy-preset","name":"旧キャラ"}"#.utf8), forKey: "MY_CHARA")
        defaults.set("legacy-preset", forKey: "CHARA_DOMAIN")
        try migration.removeSavedData()
        precondition(migration.isRetiredCharaID("legacy-preset"))
        precondition(!migration.isRetiredCharaID("com.charalarm.yui"))
        print("MyChara removal: data deletion, fallback, unrelated data preservation, retry and corrupt/legacy data passed")
    }
}
