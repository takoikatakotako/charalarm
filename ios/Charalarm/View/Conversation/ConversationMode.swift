import Foundation

/// 会話画面の起動モード。
enum ConversationMode {
    /// アプリ内単体起動（DEBUG 動線）。自前で着信音を鳴らし、終了は画面を閉じるだけ。
    case standalone
    /// CallKit 着信フロー経由。着信音・音声セッションは CallKit が管理し、
    /// 終了は CXEndCallAction 経由でシステム通話を終わらせる。
    case callKit(callUUID: UUID?)
}

/// 会話の始め方。
enum ConversationTopic {
    /// 電話（着信音を鳴らし、キャラが電話に出たところから始める）
    case call
    /// トップの「今日の予定」ボタン。キャラが今日の予定を読み上げてから、そのまま話せる
    case todaySchedule

    /// 「今日の予定」のときの最初の指示（人格プロンプトのあとに送る）
    static let todaySchedulePrompt = "ユーザーがホーム画面の「今日の予定」ボタンを押しました。電話ではないので、電話のあいさつはしないでください。" +
        "<events> にある今日の予定を、時刻の早い順に短く読み上げて、ひとこと添えてください。" +
        "予定がなければ、今日は予定がないことを伝えてください。"
}

/// 端末内音声合成で会話できるキャラかどうかの判定。
/// 現状はずんだもん専用。将来は四国めたん等の VOICEVOX キャラを追加する。
enum ConversationCapability {
    /// 会話対応キャラの charaID 一覧。
    static let capableCharaIDs: Set<String> = ["jp.zunko.zundamon"]

    static func isCapable(charaID: String?) -> Bool {
        guard let charaID = charaID else { return false }
        return capableCharaIDs.contains(charaID)
    }
}
