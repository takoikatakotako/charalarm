import Foundation

/// ユーザーが作る「自分のキャラ」。プリセットのキャラ（サーバの preset）を土台にし、見た目と名前を上書きする。
/// 設定は端末に保存し、名前・性格・声は会話のリクエストにだけ付ける。
struct MyChara: Codable, Equatable {
    /// 土台にするプリセットのキャラ
    var baseCharaID: String
    /// 名前（トップ・電話の画面に出す）
    var name: String
    /// 手持ちの VRM のファイル名（端末の MyChara フォルダの中）。nil なら土台のキャラの見た目を使う
    var importedVRMFileName: String?
    /// 土台のキャラの VRM（サーバ）。手持ちの VRM がないときに使う
    var presetModelFileURL: URL?
    /// 古い保存データにはないため optional。見た目とは独立して編集する。
    var personality: String?
    var voiceID: String?

    var conversationSettings: MyCharaConversationSettings {
        MyCharaConversationSettings(name: name, personality: personality ?? "")
    }
}

struct MyCharaConversationSettings: Encodable {
    let name: String
    let personality: String
}

struct CharaVoice: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
}
