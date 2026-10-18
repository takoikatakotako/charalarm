import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition

/// 会話中の音声認識まわり。
/// 無音時の一時的な失敗で会話を終わらせないためのリトライを含む。
extension ConversationViewState {

    /// 音声認識を最大3回試みる。無音や一時失敗では聞き直し、全滅時のみ nil。
    func recognizeUserSpeechWithRetry() async -> String? {
        for attempt in 1...3 {
            guard !shouldDismiss else { return nil }
            do {
                let input = try await recognizeUserSpeech()
                if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return input
                }
                CharalarmLogger.debug("音声認識が空でした（\(attempt)回目）")
            } catch {
                CharalarmLogger.error("音声認識エラー", error: error)
            }
            resetRecognition()
        }
        return nil
    }

    private func resetRecognition() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        task?.cancel()
        task = nil
        request = nil
        recognitionContinuation = nil
        pendingRecognizedText = nil
        engine.inputNode.removeTap(onBus: 0)
    }

    func requestSpeechRecognitionPermission() async -> Bool {
        status = .requestingPermission

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    /// ユーザーの発話を受け取る。キャラが話している最中から聞いているので、話しかけて止めた発話もここで受け取る
    private func recognizeUserSpeech() async throws -> String {
        status = .recognizingSpeech
        if let pending = pendingRecognizedText {
            pendingRecognizedText = nil
            return pending
        }
        if request == nil {
            text = ""
            try startListening()
        }
        return try await withCheckedThrowingContinuation { continuation in
            recognitionContinuation = continuation
        }
    }

    /// 音声認識を始める。キャラが話している最中に呼ぶと、言葉が聞こえたところで再生を止める
    func startListening() throws {
        guard request == nil else { return }
        try prepareAudioEngine()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        installInputTap()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.failRecognition(error)
                    return
                }
                guard let result, !result.isFinal else { return }
                self.didRecognize(result.bestTranscription.formattedString)
            }
        }
    }

    /// マイクの音を音声認識に流す。エンジンの設定が変わったら (形が変わることがあるので) 付け直す
    func installInputTap() {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
    }

    private func didRecognize(_ recognizedText: String) {
        let trimmed = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        // キャラが話している最中に言葉が聞こえたら止める (物音で止まらないよう2文字から)
        if isListeningForBargeIn && !isBargedIn {
            guard trimmed.count >= 2 else { return }
            interruptPlayback()
        }

        text = recognizedText
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: Constants.silenceDetectionTime, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecognition()
            }
        }
    }

    private func failRecognition(_ error: Error) {
        if let continuation = recognitionContinuation {
            continuation.resume(throwing: ConversationError.speechRecognitionFailed(error))
            recognitionContinuation = nil
        }
        // 受け取る前のエラーは、次に聞くときに聞き直す
        engine.inputNode.removeTap(onBus: 0)
        request = nil
        task = nil
    }

    /// 話し終わった (無音が続いた)。エンジンは会話のあいだ動かし続けるので止めない
    private func stopRecognition() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        request = nil
        task = nil

        if let continuation = recognitionContinuation {
            continuation.resume(returning: text)
            recognitionContinuation = nil
        } else {
            // まだ受け取る準備ができていない (キャラの声を止めた直後など)。次に受け取る
            pendingRecognizedText = text
        }
    }
}
