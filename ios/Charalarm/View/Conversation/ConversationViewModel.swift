import SwiftUI
import Speech
import AVFoundation
import CallKit

/// キャラとのリアルタイム音声会話（ターン制）。
/// 声（端末内の VOICEVOX か /tts の Gemini TTS）と通話の場面の指示は、キャラ情報（サーバ）から決める。
@MainActor
@Observable
class ConversationViewModel: NSObject {

    // MARK: - Observed Properties

    var text = ""
    var charaName = ""
    var status: ConversationStatus = .idle
    var conversationDuration: TimeInterval = 0
    var shouldDismiss = false

    // MARK: - Constants

    enum Constants {
        static let silenceDetectionTime: TimeInterval = 2.0
        static let maxConversationDuration: TimeInterval = 120.0
        static let conversationTimerInterval: TimeInterval = 1.0
        static let ringtoneAssetName = "ringtone"
    }

    // MARK: - Mode

    /// 起動モード（アプリ内単体 or CallKit 着信フロー）。
    private let mode: ConversationMode

    private let callController = CXCallController()

    // MARK: - Repositories

    /// 会話するキャラ。人格プロンプトはサーバ側（chara-table）が持つ。
    private let charaID: String
    /// キャラの会話の設定。会話を始めるときにサーバから取得する。
    private var conversation: CharaConversation?
    /// 会話の言語。設定で選んだ言語をキャラが話せればその言語、話せなければキャラの言語
    private var language: ConversationLanguage = .japanese
    /// 声はキャラごとに決まるので、会話の設定を取得してから作る。テストでは外から渡せる。
    private var textToSpeechRepository: TextToSpeechRepository?
    private let textGenerationRepository: TextGenerationRepository
    private let apiRepository = APIRepository()

    // MARK: - Speech Recognition

    /// 音声認識。会話の言語が決まってから作る
    var recognizer: SFSpeechRecognizer?
    let engine = AVAudioEngine()
    var request: SFSpeechAudioBufferRecognitionRequest?
    var task: SFSpeechRecognitionTask?
    var recognitionContinuation: CheckedContinuation<String, Error>?
    var silenceTimer: Timer?

    // MARK: - Audio Playback

    var audioPlayer: AVAudioPlayer?
    var playbackContinuation: CheckedContinuation<Bool, Never>?

    // MARK: - Timers / State

    private var conversationTimer: Timer?
    private var conversationStartTime: Date?
    private var chatMessages: [ChatMessage] = []
    private var mainTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        charaID: String,
        mode: ConversationMode = .standalone,
        textToSpeechRepository: TextToSpeechRepository? = nil,
        textGenerationRepository: TextGenerationRepository = BackendTextGenerationRepository()
    ) {
        self.charaID = charaID
        self.mode = mode
        self.textToSpeechRepository = textToSpeechRepository
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
                text = "ごめんなさい、うまくつながりませんでした。少し時間をあけて、またかけてみてください。"
                #if DEBUG
                text += "\n\n[DEBUG] \(error)"
                #endif
            }
        }
    }

    /// 「通話を終了」ボタン。モードにより挙動を分ける。
    func endButtonTapped() {
        switch mode {
        case .standalone:
            requestDismiss()
        case .callKit(let callUUID):
            requestCallKitEnd(callUUID: callUUID)
        }
    }

    /// 画面が閉じられる際のクリーンアップ（CallKit 終話で RootView が .top に戻ったとき等）。
    func teardown() {
        cleanupResources()
    }

    private func requestDismiss() {
        guard !shouldDismiss else { return }
        cleanupResources()
        shouldDismiss = true
    }

    /// CallKit の通話を終了する。終話は endCall 通知経由で RootView が畳む。
    private func requestCallKitEnd(callUUID: UUID?) {
        guard let callUUID = callUUID else {
            // callUUID 不明時はフォールバックで画面だけ閉じる
            requestDismiss()
            return
        }
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let error = error {
                CharalarmLogger.error("CallKit 終話に失敗", error: error)
            }
        }
    }

    /// 会話が自然終了したとき、モードに応じて画面/通話を閉じる。
    private func finishConversation() {
        switch mode {
        case .standalone:
            requestDismiss()
        case .callKit(let callUUID):
            requestCallKitEnd(callUUID: callUUID)
        }
    }

    // MARK: - Conversation Flow

    private func startConversation() async throws {
        // キャラの会話の設定を取得し、声を準備する
        status = .preparing
        let chara = try await apiRepository.fetchCharacter(charaID: charaID)
        guard let conversation = chara.conversation else {
            throw ConversationError.notConversationChara
        }
        self.conversation = conversation
        language = conversation.language(preferred: UserDefaultsRepository().getConversationLanguage())
        recognizer = SFSpeechRecognizer(locale: language.locale)
        charaName = chara.name
        let textToSpeechRepository = self.textToSpeechRepository
            ?? Self.makeTextToSpeechRepository(charaID: charaID, conversation: conversation)
        self.textToSpeechRepository = textToSpeechRepository
        try textToSpeechRepository.setupSynthesizer()
        guard !shouldDismiss else { return }

        // 音声認識の許可
        guard await requestSpeechRecognitionPermission() else {
            throw ConversationError.speechRecognitionPermissionDenied
        }
        guard !shouldDismiss else { return }

        // 着信音を再生（CallKit モードでは着信音はシステムが鳴らすのでスキップ）
        if case .standalone = mode {
            playRingtone()
        }

        // 初回の応答を生成
        status = .generatingScript
        chatMessages.append(ChatMessage(role: .system, content: conversation.openingPrompt))
        let initialScript = try await generateResponse()
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
                try await endConversation(prompt: conversation?.noInputEndingPrompt)
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
        let response = try await generateResponse()
        guard !shouldDismiss else { return }

        chatMessages.append(ChatMessage(role: .assistant, content: response))
        text = response

        try await synthesizeAndPlayVoiceInChunks(from: response)
        guard !shouldDismiss else { return }

        try await conversationLoop()
    }

    /// キャラの返事を作る。キャラがカレンダーを見るあいだは、そのひとこと（「ちょっと見てみますね」）を先に話す
    private func generateResponse() async throws -> String {
        var fillerTask: Task<Void, Never>?
        let response = try await textGenerationRepository.generateResponse(
            charaID: charaID,
            language: language,
            inputs: chatMessages
        ) { [weak self] filler in
            guard let self else { return }
            self.stopRingtone()
            self.text = filler
            fillerTask = Task { try? await self.synthesizeAndPlayVoiceInChunks(from: filler) }
        }
        // ひとことを話し終えてから返事を話す
        await fillerTask?.value
        return response
    }

    private func endConversation(prompt: String? = nil) async throws {
        if let prompt = prompt ?? conversation?.endingPrompt {
            chatMessages.append(ChatMessage(role: .system, content: prompt))
        }

        status = .generatingScript
        let farewellScript = try await generateResponse()
        chatMessages.append(ChatMessage(role: .assistant, content: farewellScript))
        text = farewellScript

        try await synthesizeAndPlayVoiceInChunks(from: farewellScript)

        status = .ended
        conversationTimer?.invalidate()

        finishConversation()
    }

    // MARK: - Text to Speech

    /// キャラの声の出し方に合わせて音声合成を選ぶ。
    private static func makeTextToSpeechRepository(charaID: String, conversation: CharaConversation) -> TextToSpeechRepository {
        switch conversation.voiceProvider {
        case .voicevox:
            return VoicevoxRepository(styleId: conversation.voicevoxStyleID)
        case .gemini:
            return BackendTextToSpeechRepository(charaID: charaID)
        }
    }

    private func synthesizeVoice(from script: String) async throws -> Data {
        guard let textToSpeechRepository = textToSpeechRepository else {
            throw ConversationError.notConversationChara
        }
        status = .synthesizingVoice
        return try await textToSpeechRepository.synthesize(text: script)
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
        textToSpeechRepository?.cleanupSynthesizer()
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
