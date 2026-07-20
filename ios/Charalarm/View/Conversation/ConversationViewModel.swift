import SwiftUI
import Speech
import AVFoundation

/// ずんだもんとのリアルタイム音声会話（ターン制）。
/// フェーズ2: アプリ内会話画面（simulated）。CallKit 着信フローへの接続はフェーズ3。
@MainActor
class ConversationViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var text = ""
    @Published var status: ConversationStatus = .idle
    @Published var conversationDuration: TimeInterval = 0
    @Published var shouldDismiss = false

    // MARK: - Constants

    enum Constants {
        static let silenceDetectionTime: TimeInterval = 2.0
        static let maxConversationDuration: TimeInterval = 120.0
        static let conversationTimerInterval: TimeInterval = 1.0
        static let locale = Locale(identifier: "ja-JP")
        static let ringtoneAssetName = "ringtone"

        /// 会話キャラの VOICEVOX スタイルID。将来はキャラ属性から渡す（ずんだもん ノーマル = 3）。
        static let voicevoxStyleId = 3

        static let systemPrompt = """
            あなたはずんだの妖精のずんだもんです。語尾に「なのだ」をつけ、親しみやすく楽しい口調で話してください。
            今は電話がかかってきて受け取ったところから会話を始めます。
            最初のセリフは必ず「電話を受けた感のある挨拶」にしてください。
            例: 「もしもし〜？ずんだもんなのだ！」、「は〜い、ずんだもんなのだ！」、「お電話ありがとうなのだ！」など。
            例を参考にしつつ、毎回少し違う言い回しにしてください。
            暴力的・攻撃的・不快な発言はしないでください。
            """

        static let endConversationPrompt = "会話時間が2分を超えたので、ずんだもんらしく親しみやすい挨拶で会話を終了してください。"
        static let noInputEndPrompt = "ユーザーの声が聞こえなくなったので、少し心配しつつ、ずんだもんらしい親しみやすい挨拶で会話を終了してください。"
    }

    // MARK: - Repositories

    private let voicevoxRepository: TextToSpeechRepository
    private let textGenerationRepository: TextGenerationRepository

    // MARK: - Speech Recognition

    let recognizer = SFSpeechRecognizer(locale: Constants.locale)
    let engine = AVAudioEngine()
    var request: SFSpeechAudioBufferRecognitionRequest?
    var task: SFSpeechRecognitionTask?
    var recognitionContinuation: CheckedContinuation<String, Error>?
    var silenceTimer: Timer?

    // MARK: - Audio Playback

    private var audioPlayer: AVAudioPlayer?
    private var playbackContinuation: CheckedContinuation<Bool, Never>?

    // MARK: - Timers / State

    private var conversationTimer: Timer?
    private var conversationStartTime: Date?
    private var chatMessages: [ChatMessage] = []
    private var mainTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        voicevoxRepository: TextToSpeechRepository = VoicevoxRepository(),
        textGenerationRepository: TextGenerationRepository = StubTextGenerationRepository()
    ) {
        self.voicevoxRepository = voicevoxRepository
        self.textGenerationRepository = textGenerationRepository
    }

    // MARK: - Public Methods

    func onAppear() {
        guard status == .idle else { return }
        mainTask = Task {
            do {
                try await startConversation()
            } catch {
                CharalarmLogger.error("会話エラー", error: error)
                text = "ごめんなさいなのだ。エラーが発生してしまったのだ。少し時間をあけて、またリトライしてくれると嬉しいのだ〜。"
                #if DEBUG
                text += "\n\n[DEBUG] \(error)"
                #endif
            }
        }
    }

    func requestDismiss() {
        guard !shouldDismiss else { return }
        cleanupResources()
        shouldDismiss = true
    }

    // MARK: - Conversation Flow

    private func startConversation() async throws {
        // VOICEVOX 初期化
        status = .initializingVoiceVox
        try voicevoxRepository.setupSynthesizer()
        guard !shouldDismiss else { return }

        // 音声認識の許可
        guard await requestSpeechRecognitionPermission() else {
            throw ConversationError.speechRecognitionPermissionDenied
        }
        guard !shouldDismiss else { return }

        // 着信音を再生
        playRingtone()

        // 初回の応答を生成
        status = .generatingScript
        chatMessages.append(ChatMessage(role: .system, content: Constants.systemPrompt))
        let initialScript = try await textGenerationRepository.generateResponse(inputs: chatMessages)
        guard !shouldDismiss else { return }

        stopRingtone()
        chatMessages.append(ChatMessage(role: .assistant, content: initialScript))
        text = initialScript
        startConversationTracking()

        try await synthesizeAndPlayVoiceInChunks(from: initialScript)
        guard !shouldDismiss else { return }

        try await conversationLoop()
    }

    private func conversationLoop() async throws {
        guard !shouldDismiss else { return }

        // ユーザーの発話を認識（無音や一時失敗は聞き直す）
        guard let userInput = await recognizeUserSpeechWithRetry() else {
            if !shouldDismiss {
                try await endConversation(prompt: Constants.noInputEndPrompt)
            }
            return
        }
        guard !shouldDismiss else { return }

        if shouldEndConversation() {
            try await endConversation()
            return
        }

        chatMessages.append(ChatMessage(role: .user, content: userInput))

        status = .generatingScript
        let response = try await textGenerationRepository.generateResponse(inputs: chatMessages)
        guard !shouldDismiss else { return }

        chatMessages.append(ChatMessage(role: .assistant, content: response))
        text = response

        try await synthesizeAndPlayVoiceInChunks(from: response)
        guard !shouldDismiss else { return }

        try await conversationLoop()
    }

    private func endConversation(prompt: String = Constants.endConversationPrompt) async throws {
        chatMessages.append(ChatMessage(role: .system, content: prompt))

        status = .generatingScript
        let farewellScript = try await textGenerationRepository.generateResponse(inputs: chatMessages)
        chatMessages.append(ChatMessage(role: .assistant, content: farewellScript))
        text = farewellScript

        try await synthesizeAndPlayVoiceInChunks(from: farewellScript)

        status = .ended
        conversationTimer?.invalidate()
    }

    // MARK: - VOICEVOX

    private func synthesizeVoice(from script: String) async throws -> Data {
        status = .synthesizingVoice
        return try await voicevoxRepository.synthesize(text: script, styleId: Constants.voicevoxStyleId)
    }

    private func synthesizeAndPlayVoiceInChunks(from text: String) async throws {
        let chunks = TextChunker.split(text)
        guard !chunks.isEmpty else { return }

        // 最初のチャンクを合成
        var currentAudioData: Data? = try await synthesizeVoice(from: chunks[0])

        for i in 0..<chunks.count - 1 {
            guard !shouldDismiss else { return }
            // 次のチャンクを並行合成しつつ現在のチャンクを再生（レイテンシ隠蔽）
            async let nextAudio = synthesizeVoice(from: chunks[i + 1])
            if let audioData = currentAudioData {
                try await playVoice(audioData)
            }
            currentAudioData = try await nextAudio
        }

        guard !shouldDismiss else { return }
        if let audioData = currentAudioData {
            try await playVoice(audioData)
        }
    }

    // MARK: - Audio Playback

    private func playRingtone() {
        guard let asset = NSDataAsset(name: Constants.ringtoneAssetName) else {
            CharalarmLogger.error("着信音アセットが見つかりません", error: ConversationError.ringtoneNotFound)
            return
        }
        audioPlayer = try? AVAudioPlayer(data: asset.data)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }

    private func stopRingtone() {
        audioPlayer?.stop()
    }

    private func playVoice(_ audioData: Data) async throws {
        status = .playingVoice

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(data: audioData)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()

        let success = await withCheckedContinuation { continuation in
            playbackContinuation = continuation
        }
        if !success {
            throw ConversationError.audioPlaybackFailed
        }
    }

    // MARK: - Conversation Tracking

    private func startConversationTracking() {
        conversationStartTime = Date()
        conversationTimer?.invalidate()
        conversationTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.conversationTimerInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.conversationStartTime else { return }
                self.conversationDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func shouldEndConversation() -> Bool {
        guard let startTime = conversationStartTime else { return false }
        return Date().timeIntervalSince(startTime) >= Constants.maxConversationDuration
    }

    // MARK: - Cleanup

    private func cleanupResources() {
        mainTask?.cancel()
        mainTask = nil

        silenceTimer?.invalidate()
        silenceTimer = nil
        conversationTimer?.invalidate()
        conversationTimer = nil

        task?.cancel()
        task?.finish()
        task = nil
        request?.endAudio()
        request = nil

        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        audioPlayer?.stop()
        audioPlayer = nil

        chatMessages.removeAll()
        voicevoxRepository.cleanupSynthesizer()
    }
}

// MARK: - AVAudioPlayerDelegate

extension ConversationViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            playbackContinuation?.resume(returning: flag)
            playbackContinuation = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            CharalarmLogger.error("音声デコードエラー", error: error)
            playbackContinuation?.resume(returning: false)
            playbackContinuation = nil
        }
    }
}
