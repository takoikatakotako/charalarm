import Foundation

// MARK: - Conversation Tracking

/// 通話時間の表示と、設定した時間での自動終了。
/// 上限の時間になったらお別れに進み、お別れが長引いても少し待って電話を切る。
extension ConversationViewState {

    func startConversationTracking() {
        conversationStartTime = Date()
        conversationTimer?.invalidate()
        conversationTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.conversationTimerInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.conversationStartTime else { return }
                self.conversationDuration = Date().timeIntervalSince(startTime)
                self.checkTimeLimit()
            }
        }
    }

    /// 上限の時間になったらお別れに進め、それでも終わらなければ電話を切る。
    /// 「今日の予定」は電話ではない（読み上げるだけ）ので、時間では止めない
    private func checkTimeLimit() {
        guard listensToUser, !isEndRequested, !isFinished else { return }
        if conversationDuration >= timeLimit.hardDeadline {
            CharalarmLogger.breadcrumb("会話: 上限を過ぎても終わらないので切る limit=\(timeLimit.rawValue)")
            forceEnd()
        } else if !isTimeUp, conversationDuration >= timeLimit.duration {
            isTimeUp = true
            CharalarmLogger.breadcrumb("会話: 上限の時間になった limit=\(timeLimit.rawValue) status=\(status)")
            // 黙って返事を待っていたら、待つのをやめてお別れに進む。
            // ユーザーが話している途中なら言い終えるのを待ち、キャラが返事を作っている・話している最中なら終わってから、その話に答えつつお別れする
            if status == .recognizingSpeech, heardText.isEmpty {
                stopListening()
            }
        }
    }

    /// 返事を作っている・話している途中でも止めて、電話を切る
    private func forceEnd() {
        mainTask?.cancel()
        mainTask = nil
        voicePlayerNode.stop()
        finishPlayback()
        stopListening()
        conversationTimer?.invalidate()
        conversationTimer = nil
        status = .ended
        finishConversation()
    }
}
