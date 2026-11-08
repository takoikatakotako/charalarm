import Foundation

/// ユーザーが作る「自分のキャラ」。プリセットのキャラ（サーバの preset）を土台にし、見た目と名前を上書きする。
/// 声・性格・アラームのボイスは土台のキャラのものを使う。端末の中だけに保存し、サーバには送らない
struct MyChara: Codable, Equatable {
    /// 土台にするプリセットのキャラ
    var baseCharaID: String
    /// 名前（トップ・電話の画面に出す）
    var name: String
    /// 手持ちの VRM のファイル名（端末の MyChara フォルダの中）。nil なら土台のキャラの見た目を使う
    var importedVRMFileName: String?
    /// 土台のキャラの VRM（サーバ）。手持ちの VRM がないときに使う
    var presetModelFileURL: URL?
}
