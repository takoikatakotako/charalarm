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
            guard !shouldDismiss, !Task.isCancelled else { return nil }
            do {
                let input = try await recognizeUserSpeech()
                if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    CharalarmLogger.breadcrumb("聞き取り: できた chars=\(input.count)")
                    return input
                }
                CharalarmLogger.breadcrumb("聞き取り: 空（\(attempt)回目）")
            } catch {
                CharalarmLogger.error("音声認識エラー", error: error)
                resetRecognition()
                // マイクの準備ができるまで (電話に出た直後など) 少し待ってから聞き直す
                try? await Task.sleep(for: .milliseconds(500))
                continue
            }
            resetRecognition()
        }
        CharalarmLogger.breadcrumb("聞き取り: 3回とも聞き取れなかった")
        return nil
    }

    /// 聞き取りをやめる（停止ボタン）。受け取りを待っていたら、止めたことにして返す
    func stopListening() {
        resetRecognitionTask()
        request?.endAudio()
        request = nil
        if let continuation = recognitionContinuation {
            continuation.resume(throwing: CancellationError())
            recognitionContinuation = nil
        }
        pendingRecognizedText = nil
    }

    private func resetRecognitionTask() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        task?.cancel()
        task = nil
        // 読み上げるだけのときはマイクに触らない
        if listensToUser {
            engine.inputNode.removeTap(onBus: 0)
        }
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
        // キャラが話しているあいだに聞こえたのに止めなかった（相づちだった）なら、返事としては聞き直す
        if request != nil, !isBargedIn, !heardText.isEmpty {
            resetRecognitionTask()
            request?.endAudio()
            request = nil
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
        heardText = ""
        heardStartTime = nil

        guard installInputTap() else {
            self.request = nil
            throw ConversationError.microphoneNotReady
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                // やめた聞き取り (相づちで聞き直した等) からの知らせは、今の聞き取りに混ぜない
                guard let self, self.request === request else { return }
                if let error {
                    self.failRecognition(error)
                    return
                }
                guard let result, !result.isFinal else { return }
                self.didRecognize(result.bestTranscription)
            }
        }
    }

    /// マイクの音を音声認識に流す。エンジンの設定が変わったら (形が変わることがあるので) 付け直す。
    /// 電話に出た直後などはマイクの形がまだ決まっておらず (0Hz・0ch)、そのまま付けると例外で落ちる。
    /// そのときは付けずに false を返す
    @discardableResult
    func installInputTap() -> Bool {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            CharalarmLogger.breadcrumb("聞き取り: マイクの準備ができていない rate=\(format.sampleRate) ch=\(format.channelCount)")
            return false
        }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        return true
    }

    private func didRecognize(_ transcription: SFTranscription) {
        let recognizedText = transcription.formattedString
        guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let heardStartTime = self.heardStartTime ?? Date()
        self.heardStartTime = heardStartTime

        // キャラが話している最中は、しばらく話し続けたら止める。
        // 言葉の中身ではなく長さで見るので、どの言語でも相づち（「うん」「うーん…」「yeah」など）では止まらない。
        // 「うーん」と伸ばしても1語のままで、「うんうん」と繰り返しても同じ語なので、違う語が続いたときだけにする
        if isListeningForBargeIn && !isBargedIn {
            let elapsed = Date().timeIntervalSince(heardStartTime)
            let words = Set(transcription.segments.map { $0.substring.lowercased() }).count
            if elapsed >= Constants.bargeInMinimumDuration && words >= Constants.bargeInMinimumWords {
                CharalarmLogger.breadcrumb("聞き取り: 話しかけられた words=\(words)")
                interruptPlayback()
            }
        }
        heardText = recognizedText
        if !isListeningForBargeIn || isBargedIn {
            text = recognizedText
        }
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
            continuation.resume(returning: heardText)
            recognitionContinuation = nil
        } else if isListeningForBargeIn && !isBargedIn {
            // キャラが話している最中の相づちだけだった（止めるほど話さなかった）。返事として受け取らず、聞き直す
            CharalarmLogger.breadcrumb("聞き取り: 相づちなので聞き流した")
            do {
                try startListening()
            } catch {
                CharalarmLogger.error("流している最中の聞き取りを始め直せませんでした", error: error)
            }
        } else {
            // まだ受け取る準備ができていない (キャラの声を止めた直後など)。次に受け取る
            pendingRecognizedText = heardText
        }
    }
}
