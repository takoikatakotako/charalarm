import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Playback

/// 着信音とキャラの声の再生。
/// キャラの声は音声認識と同じ AVAudioEngine から流し、エコーキャンセル (voice processing) を効かせる。
/// こうすると、再生中もマイクを開いておいても、キャラ自身の声を拾わない (話しかけたら止められる)。
extension ConversationViewState {

    /// キャラの声の形 (Gemini TTS も VOICEVOX も 24kHz・モノラル)。違う形の音声は変換する
    static let voiceFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false)!

    func playRingtone() {
        guard let asset = NSDataAsset(name: Constants.ringtoneAssetName) else {
            CharalarmLogger.error("着信音アセットが見つかりません", error: ConversationError.ringtoneNotFound)
            return
        }
        audioPlayer = try? AVAudioPlayer(data: asset.data)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }

    func stopRingtone() {
        audioPlayer?.stop()
    }

    /// 会話のあいだ動かし続けるオーディオエンジンを用意する。音声セッションも会話のあいだは切り替えない
    func prepareAudioEngine() throws {
        guard !isAudioEngineReady else {
            // 音声の経路が変わるなどしてエンジンが止まっていたら、起動し直す
            try startAudioEngineIfNeeded()
            return
        }
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // エコーキャンセル。エンジンを動かす前に有効にする
        try engine.inputNode.setVoiceProcessingEnabled(true)
        engine.attach(voicePlayerNode)
        engine.connect(voicePlayerNode, to: engine.mainMixerNode, format: Self.voiceFormat)
        engine.prepare()
        try engine.start()
        isAudioEngineReady = true

        // エンジンは音声の経路や設定が変わると自分で止まる (エコーキャンセルを有効にした直後など)。止まったら起動し直す
        engineConfigurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.restartAudioEngineAfterConfigurationChange()
            }
        }
    }

    func startAudioEngineIfNeeded() throws {
        guard !engine.isRunning else { return }
        engine.prepare()
        try engine.start()
    }

    private func restartAudioEngineAfterConfigurationChange() {
        guard isAudioEngineReady, !shouldDismiss else { return }
        // 流している途中で止まると、終わったという知らせが来ないことがある。待ったままにならないよう終わったことにする
        finishPlayback()
        // 聞いている途中なら、マイクの受け取りも付け直す
        if request != nil {
            installInputTap()
        }
        do {
            try startAudioEngineIfNeeded()
        } catch {
            CharalarmLogger.error("オーディオエンジンを起動し直せませんでした", error: error)
        }
    }

    func playVoice(_ audioData: Data) async throws {
        status = .playingVoice
        try prepareAudioEngine()
        let buffer = try Self.makeVoiceBuffer(from: audioData)
        // 合成を待っているあいだにエンジンが止まっていることがあるので、流す直前にも確かめる
        try startAudioEngineIfNeeded()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            playbackContinuation = continuation
            voicePlayerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                Task { @MainActor in
                    self?.finishPlayback()
                }
            }
            voicePlayerNode.play()
        }
    }

    /// 再生中に話しかけられたら止める。残りのチャンクも流さない
    func interruptPlayback() {
        guard isListeningForBargeIn, !isBargedIn else { return }
        isBargedIn = true
        voicePlayerNode.stop()
        finishPlayback()
    }

    private func finishPlayback() {
        playbackContinuation?.resume()
        playbackContinuation = nil
    }

    /// WAV などの音声データを、キャラの声の形の PCM バッファにする
    static func makeVoiceBuffer(from audioData: Data) throws -> AVAudioPCMBuffer {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).wav")
        try audioData.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let file = try AVAudioFile(forReading: fileURL)
        guard let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw ConversationError.audioPlaybackFailed
        }
        try file.read(into: source)
        if source.format == voiceFormat {
            return source
        }

        guard let converter = AVAudioConverter(from: source.format, to: voiceFormat) else {
            throw ConversationError.audioPlaybackFailed
        }
        let ratio = voiceFormat.sampleRate / source.format.sampleRate
        let capacity = AVAudioFrameCount(Double(source.frameLength) * ratio) + 1024
        guard let converted = AVAudioPCMBuffer(pcmFormat: voiceFormat, frameCapacity: capacity) else {
            throw ConversationError.audioPlaybackFailed
        }
        var consumed = false
        var conversionError: NSError?
        converter.convert(to: converted, error: &conversionError) { _, inputStatus in
            if consumed {
                inputStatus.pointee = .endOfStream
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return source
        }
        if let conversionError {
            throw conversionError
        }
        return converted
    }
}
