import Foundation

/// 応答した電話
struct AnsweredCall: Equatable {
    let charaID: String
    let charaName: String
    let callUUID: UUID
    /// 会話画面で出るか（でなければ録音ボイスを流す画面）
    let conversation: Bool
}

/// 通話中の電話を、電話が終わるまで持っておく。
/// アプリが動いていない状態で電話に出ると、RootView が知らせを受け取る準備をする前に応答が届くことがある。
/// 知らせを取り逃しても、ここを見れば電話の画面に合わせられる
@MainActor final class AnsweredCallStore {
    static let shared = AnsweredCallStore()

    private(set) var call: AnsweredCall?
    /// CallKit が電話の音声を使えるようにした。これより前に流した音は聞こえない
    private(set) var isAudioActive = false

    func answer(_ call: AnsweredCall) {
        self.call = call
        NotificationCenter.default.post(name: NSNotification.answerCall, object: self)
    }

    func activateAudio() {
        isAudioActive = true
        NotificationCenter.default.post(name: NSNotification.callAudioDidActivate, object: self)
    }

    func end() {
        call = nil
        isAudioActive = false
        NotificationCenter.default.post(name: NSNotification.endCall, object: self)
    }
}
