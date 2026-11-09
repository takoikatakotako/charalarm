import Foundation

// Run with the real entity, without modifying UserDefaults or any app data:
// swiftc -parse-as-library Charalarm/Entity/MyChara.swift scripts/tests/my-chara-settings.swift -o /tmp/my-chara-settings
@main
enum MyCharaSettingsChecks {
    static func main() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        let legacy = Data(#"{"baseCharaID":"com.charalarm.preset.hinata","name":"以前のキャラ"}"#.utf8)
        var character = try decoder.decode(MyChara.self, from: legacy)
        precondition(character.personality == nil && character.voiceID == nil)
        precondition(character.conversationSettings.name == "以前のキャラ")
        precondition(character.conversationSettings.personality.isEmpty)

        character.personality = "落ち着いていて、丁寧に話す友達"
        character.voiceID = "Charon"
        character.importedVRMFileName = "my-avatar.vrm"
        let restored = try decoder.decode(MyChara.self, from: encoder.encode(character))
        precondition(restored == character)

        // Appearance changes must keep the user's own personality, voice and VRM.
        character.baseCharaID = "com.charalarm.preset.ren"
        let changed = try decoder.decode(MyChara.self, from: encoder.encode(character))
        precondition(changed.personality == restored.personality)
        precondition(changed.voiceID == restored.voiceID)
        precondition(changed.importedVRMFileName == restored.importedVRMFileName)

        let payload = try JSONSerialization.jsonObject(with: encoder.encode(changed.conversationSettings)) as? [String: String]
        precondition(payload?["name"] == character.name)
        precondition(payload?["personality"] == character.personality)
        precondition(payload?["voiceID"] == nil)
        print("MyChara: legacy decoding, save/reload, appearance changes and conversation payload passed")
    }
}
