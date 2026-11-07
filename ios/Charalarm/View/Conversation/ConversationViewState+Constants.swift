import Foundation

// MARK: - Constants

extension ConversationViewState {
    enum Constants {
        /// 話し終えてからこれだけ黙っていたら、言い終えたとみなして返事を作る。短いほどテンポがよいが、言葉の途中の間で切れやすい
        static let silenceDetectionTime: TimeInterval = 1.0
        /// キャラが話している最中に、間を空けずにこれだけ声を出し続けたら話しかけとみなして止める（これより短いのは相づち）。
        /// 語と語のあいだの無音は入れない。実機で試して決める
        static let bargeInMinimumDuration: TimeInterval = 0.8
        /// これより長く間が空いたら、話し続けたことにしない（間を空けた「うん」「へー」を足し合わせない）
        static let bargeInMaximumPause: TimeInterval = 0.4
        /// 話しかけとみなすのに要る、違う語の数（「うーん」「うんうん」は1語）
        static let bargeInMinimumWords = 2
        /// ユーザーが話せる回数。読み上げの費用が膨らまないよう、この回数で最後の返事をお別れのあいさつにする
        static let maxUserTurns = 3
        static let conversationTimerInterval: TimeInterval = 1.0
        static let ringtoneAssetName = "ringtone"
    }
}
