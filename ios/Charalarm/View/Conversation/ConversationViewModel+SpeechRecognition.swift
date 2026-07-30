import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition

/// 会話中の音声認識まわり。
/// 無音時の一時的な失敗で会話を終わらせないためのリトライを含む。
extension ConversationViewModel {

    /// 音声認識を最大3回試みる。無音や一時失敗では聞き直し、全滅時のみ nil。
    func recognizeUserSpeechWithRetry() async -> String? {
        for attempt in 1...3 {
            guard !shouldDismiss else { return nil }
            do {
                let input = try await recognizeUserSpeech()
                if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return input
                }
                print("音声認識が空でした（\(attempt)回目）")
            } catch {
                print("音声認識エラー（\(attempt)回目）: \(error)")
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
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
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

    private func recognizeUserSpeech() async throws -> String {
        status = .recognizingSpeech
        text = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                Task { @MainActor in
                    self.recognitionContinuation?.resume(throwing: ConversationError.speechRecognitionFailed(error))
                    self.recognitionContinuation = nil
                }
                return
            }

            guard let result = result, !result.isFinal else { return }

            let recognizedText = result.bestTranscription.formattedString
            DispatchQueue.main.async {
                self.text = recognizedText
            }

            self.silenceTimer?.invalidate()
            self.silenceTimer = Timer.scheduledTimer(
                withTimeInterval: Constants.silenceDetectionTime,
                repeats: false
            ) { _ in
                Task { @MainActor in
                    self.stopRecognition()
                }
            }
        }

        try engine.start()

        return try await withCheckedThrowingContinuation { continuation in
            recognitionContinuation = continuation
        }
    }

    private func stopRecognition() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()

        recognitionContinuation?.resume(returning: text)
        recognitionContinuation = nil
    }
}
