import SwiftUI
import Speech
import AVFoundation
import CallKit

/// キャラとのリアルタイム音声会話（ターン制）。
/// 声（端末内の VOICEVOX か /tts の Gemini TTS）と通話の場面の指示は、キャラ情報（サーバ）から決める。
@MainActor @Observable
final class ConversationViewState: NSObject {

    // MARK: - Observed Properties

    var text = ""
    var charaName = ""
    var status: ConversationStatus = .idle
    var conversationDuration: TimeInterval = 0
    var shouldDismiss = false
    /// 「今日の予定」で、停止ボタンを押して黙っている（画面は閉じない）
    var isStopped = false
    /// 3D で出すキャラのモデル（見た目が 3D のとき）
    var vrmModelFileURL: URL?
    /// 立ち絵のキャラの絵（見た目が 3D でないとき。「今日の予定」の右下に出す）
    var charaImage: UIImage?
    /// 「今日の予定」のとき、画面に出す今日の予定（それ以外は nil）
    var todayEvents: [TodayEvent]?

    // MARK: - Constants

    enum Constants {
        static let silenceDetectionTime: TimeInterval = 2.0
        static let maxConversationDuration: TimeInterval = 120.0
        /// ユーザーが話せる回数。読み上げの費用が膨らまないよう、この回数で最後の返事をお別れのあいさつにする
        static let maxUserTurns = 4
        static let conversationTimerInterval: TimeInterval = 1.0
        static let ringtoneAssetName = "ringtone"
    }

    /// 今日の会話・読み上げの上限を超えたとき、サーバが返す
    private static let usageLimitStatusCode = 429
    private static let usageLimitMessage = "今日はたくさんお話ししたので、続きはまた明日お話ししましょう。"

    // MARK: - Mode

    /// 起動モード（アプリ内単体 or CallKit 着信フロー）。
    private let mode: ConversationMode
    private let topic: ConversationTopic

    private let callController = CXCallController()

    // MARK: - Repositories

    /// 会話するキャラ。人格プロンプトはサーバ側（chara-table）が持つ。
    let charaID: String
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
    /// キャラの声を流すプレーヤー (音声認識と同じエンジンにつなぐ)
    let voicePlayerNode = AVAudioPlayerNode()
    var playbackContinuation: CheckedContinuation<Void, Never>?
    var isAudioEngineReady = false
    /// エンジンの設定が変わった (止まった) ことの通知
    var engineConfigurationObserver: NSObjectProtocol?
    /// キャラが話している最中も聞いていて、話しかけられたら止める
    var isListeningForBargeIn = false
    /// 話しかけられて、キャラの声を途中で止めた
    var isBargedIn = false
    /// 受け取る準備ができる前に話し終わった発話
    var pendingRecognizedText: String?

    // MARK: - Timers / State

    private var conversationTimer: Timer?
    private var conversationStartTime: Date?
    private var chatMessages: [ChatMessage] = []
    private var mainTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        charaID: String,
        mode: ConversationMode = .standalone,
        topic: ConversationTopic = .call,
        textToSpeechRepository: TextToSpeechRepository? = nil,
        textGenerationRepository: TextGenerationRepository = BackendTextGenerationRepository()
    ) {
        self.charaID = charaID
        self.mode = mode
        self.topic = topic
        self.textToSpeechRepository = textToSpeechRepository
        self.textGenerationRepository = textGenerationRepository
    }

    // MARK: - Public Methods

    /// 「今日の予定」の停止ボタン。読み上げも聞き取りもやめて黙る（画面は閉じない）
    func stopSpeaking() {
        guard !isStopped else { return }
        isStopped = true
        mainTask?.cancel()
        mainTask = nil
        voicePlayerNode.stop()
        finishPlayback()
        stopListening()
        conversationTimer?.invalidate()
        conversationTimer = nil
        status = .ended
        CharalarmLogger.breadcrumb("会話: 停止ボタンで止めた")
    }

    /// 「今日の予定」の再生ボタン。予定を読み直して、もう一度読み上げてもらう
    func replayTodaySchedule() {
        guard isStopped, !shouldDismiss else { return }
        isStopped = false
        reloadTodayEvents()
        CharalarmLogger.breadcrumb("会話: 再生ボタンで読み直す")
        chatMessages = [ChatMessage(role: .system, content: ConversationTopic.todaySchedulePrompt)]
        mainTask = Task {
            do {
                try await speakFirstAndTalk(todayEvents: .always)
            } catch where Task.isCancelled {
                // 停止ボタンで止めた
            } catch CharalarmError.httpStatus(_, statusCode: Self.usageLimitStatusCode) {
                text = Self.usageLimitMessage
            } catch {
                CharalarmLogger.error("会話エラー", error: error, attributes: [
                    "conversation_status": "\(status)",
                    "conversation_mode": mode.logName,
                    "conversation_topic": topic.logName,
                    "conversation_language": language.rawValue
                ])
                text = "ごめんなさい、うまくつながりませんでした。少し時間をあけて、またかけてみてください。"
            }
        }
    }

    /// 画面に出す今日の予定を読み直す（使うカレンダーを選び直したとき）
    func reloadTodayEvents() {
        todayEvents = CalendarRepository().todayEvents()
    }

    func onAppear() {
        guard status == .idle else { return }
        mainTask = Task {
            do {
                try await startConversation()
            } catch where Task.isCancelled {
                // 停止ボタンで止めた
            } catch let error as ConversationError where error.isPermissionDenied {
                // ユーザーが自分で直せるので、何をすればよいかを出す
                text = error.localizedDescription
            } catch CharalarmError.httpStatus(_, statusCode: Self.usageLimitStatusCode) {
                text = Self.usageLimitMessage
            } catch {
                CharalarmLogger.error("会話エラー", error: error, attributes: [
                    "conversation_status": "\(status)",
                    "conversation_mode": mode.logName,
                    "conversation_topic": topic.logName,
                    "conversation_language": language.rawValue
                ])
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
    /// 「今日の予定」は予定を見られるよう画面を閉じず、黙って再生ボタンを出す。
    private func finishConversation() {
        if case .todaySchedule = topic {
            stopSpeaking()
            return
        }
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
        CharalarmLogger.breadcrumb("会話: 開始 chara=\(charaID) mode=\(mode.logName) topic=\(topic.logName)")
        let chara = try await apiRepository.fetchCharacter(charaID: charaID)
        guard let conversation = chara.conversation else {
            throw ConversationError.notConversationChara
        }
        self.conversation = conversation
        language = conversation.language(preferred: UserDefaultsRepository().getConversationLanguage())
        recognizer = SFSpeechRecognizer(locale: language.locale)
        CharalarmLogger.breadcrumb("会話: 設定を取得 language=\(language.rawValue) voice=\(conversation.voiceProvider.rawValue)")
        charaName = chara.name
        // ユーザーがキャラ詳細で選んだ見た目（なければ既定）が 3D なら、会話の画面にも出す
        if case .vrm(let modelFileURL) = chara.appearance(preferred: UserDefaultsRepository().getPreferredAppearance(charaID: charaID)) {
            vrmModelFileURL = modelFileURL
        } else {
            charaImage = Self.loadCharaImage(charaID: charaID)
        }
        let textToSpeechRepository = self.textToSpeechRepository
            ?? Self.makeTextToSpeechRepository(charaID: charaID, conversation: conversation)
        self.textToSpeechRepository = textToSpeechRepository
        try textToSpeechRepository.setupSynthesizer()
        guard !isFinished else { return }

        // 音声認識とマイクの許可。会話の最初からマイクを開くので、録音を始める前に確かめる
        if listensToUser {
            guard await requestSpeechRecognitionPermission() else {
                throw ConversationError.speechRecognitionPermissionDenied
            }
            guard await AVAudioApplication.requestRecordPermission() else {
                throw ConversationError.microphonePermissionDenied
            }
        }
        guard !isFinished else { return }

        // 着信音を再生（CallKit モードでは着信音はシステムが鳴らすのでスキップ。「今日の予定」は電話ではないので鳴らさない）
        if case .standalone = mode, topic.isCall {
            playRingtone()
        }

        // 初回の応答を生成
        switch topic {
        case .call:
            chatMessages.append(ChatMessage(role: .system, content: conversation.openingPrompt))
            // 最初のひとことは、設定でオンにしていれば今日の予定に触れる
            try await speakFirstAndTalk(todayEvents: .ifEnabled)
        case .todaySchedule:
            // キャラが読み上げる予定を、画面にも出す
            reloadTodayEvents()
            chatMessages.append(ChatMessage(role: .system, content: ConversationTopic.todaySchedulePrompt))
            try await speakFirstAndTalk(todayEvents: .always)
        case .trendNews(let news):
            chatMessages.append(ChatMessage(role: .system, content: ConversationTopic.trendNewsPrompt(news)))
            try await speakFirstAndTalk()
        }
    }

    /// キャラの最初のひとことを話して、そのまま会話を続ける
    private func speakFirstAndTalk(todayEvents: TodayEventsPolicy = .none) async throws {
        status = .generatingScript
        let initialScript = try await generateResponse(todayEvents: todayEvents)
        guard !isFinished else { return }

        stopRingtone()
        chatMessages.append(ChatMessage(role: .assistant, content: initialScript))
        text = initialScript
        startConversationTracking()

        try await synthesizeAndPlayVoiceInChunks(from: initialScript, interruptible: listensToUser)
        guard !isFinished else { return }

        guard listensToUser else {
            // 一方的に話すだけ（「今日の予定」）。話し終えたら止まる
            finishConversation()
            return
        }
        try await conversationLoop()
    }

    private func conversationLoop() async throws {
        guard !isFinished else { return }

        // ユーザーの発話を認識（無音や一時失敗は聞き直す）
        guard let userInput = await recognizeUserSpeechWithRetry() else {
            if !isFinished {
                try await endConversation(prompt: conversation?.noInputEndingPrompt)
            }
            return
        }
        guard !isFinished else { return }

        if shouldEndConversation() {
            try await endConversation()
            return
        }

        chatMessages.append(ChatMessage(role: .user, content: userInput))

        // 話した回数が上限に届いたら、今の話に答えつつ締めくくる
        if userTurnCount >= Constants.maxUserTurns {
            try await endConversation()
            return
        }

        status = .generatingScript
        let response = try await generateResponse()
        guard !isFinished else { return }

        chatMessages.append(ChatMessage(role: .assistant, content: response))
        text = response

        try await synthesizeAndPlayVoiceInChunks(from: response)
        guard !isFinished else { return }

        try await conversationLoop()
    }

    /// キャラの返事を作る。キャラがカレンダーを見るあいだは、そのひとこと（「ちょっと見てみますね」）を先に話す
    private func generateResponse(todayEvents: TodayEventsPolicy = .none) async throws -> String {
        CharalarmLogger.breadcrumb("返事: 作る messages=\(chatMessages.count)")
        var fillerTask: Task<Void, Never>?
        let response = try await textGenerationRepository.generateResponse(
            charaID: charaID,
            language: language,
            inputs: chatMessages,
            todayEvents: todayEvents
        ) { [weak self] filler in
            guard let self else { return }
            self.stopRingtone()
            self.text = filler
            CharalarmLogger.breadcrumb("返事: カレンダーを見るひとこと chars=\(filler.count)")
            fillerTask = Task {
                do {
                    try await self.synthesizeAndPlayVoiceInChunks(from: filler, interruptible: false)
                } catch {
                    // ひとことが流せなくても返事は続ける。ただ無音になった理由は残す
                    CharalarmLogger.error("カレンダーを見るひとことを流せませんでした", error: error)
                }
            }
        }
        // ひとことを話し終えてから返事を話す
        await fillerTask?.value
        CharalarmLogger.breadcrumb("返事: できた chars=\(response.count)")
        return response
    }

    private func endConversation(prompt: String? = nil) async throws {
        if let prompt = prompt ?? conversation?.endingPrompt {
            chatMessages.append(ChatMessage(role: .system, content: prompt))
        }

        status = .generatingScript
        CharalarmLogger.breadcrumb("会話: 終える")
        let farewellScript = try await generateResponse()
        chatMessages.append(ChatMessage(role: .assistant, content: farewellScript))
        text = farewellScript

        try await synthesizeAndPlayVoiceInChunks(from: farewellScript, interruptible: false)

        status = .ended
        conversationTimer?.invalidate()
        CharalarmLogger.breadcrumb("会話: 終了")

        finishConversation()
    }

    /// 端末に保存してあるキャラの立ち絵（ふつうの表情があればそれ）
    private static func loadCharaImage(charaID: String) -> UIImage? {
        guard let resource = try? LocalCharaResourceUseCase().loadCharaResource(charaID: charaID) else {
            return nil
        }
        let expression = resource.expressions["normal"] ?? resource.expressions.values.first
        guard let imageName = expression?.imageFileNames.first,
              let data = try? FileRepository().loadData(directoryName: charaID, fileName: imageName) else {
            return nil
        }
        return UIImage(data: data)
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
        do {
            return try await textToSpeechRepository.synthesize(text: script)
        } catch {
            CharalarmLogger.breadcrumb("声: 合成に失敗 chars=\(script.count)")
            throw error
        }
    }

    /// キャラの返事をチャンクに分けて、合成しながら流す。
    /// interruptible なら、流している最中に話しかけられたら止め、会話の履歴をそこまでに縮める。
    private func synthesizeAndPlayVoiceInChunks(from text: String, interruptible: Bool = true) async throws {
        let chunks = TextChunker.split(text)
        guard !chunks.isEmpty else { return }
        CharalarmLogger.breadcrumb("声: 流す chunks=\(chunks.map(\.count))")

        isBargedIn = false
        if interruptible {
            // 話しかけて止められるよう、流している最中も聞く。マイクの準備ができていなければ、止められないまま流す
            do {
                try startListening()
                isListeningForBargeIn = true
            } catch {
                CharalarmLogger.error("流している最中の聞き取りを始められませんでした", error: error)
            }
        }
        defer { isListeningForBargeIn = false }

        var playedCount = 0
        var currentAudioData: Data? = try await synthesizeVoice(from: chunks[0])
        for i in 0..<chunks.count {
            guard !isFinished, !isStopped, !isBargedIn else { break }
            // 次のチャンクを並行合成しつつ現在のチャンクを再生（レイテンシ隠蔽）
            async let nextAudio: Data? = i + 1 < chunks.count ? synthesizeVoice(from: chunks[i + 1]) : nil
            if let audioData = currentAudioData {
                try await playVoice(audioData)
            }
            if !isBargedIn {
                playedCount += 1
            }
            currentAudioData = try await nextAudio
        }

        if isBargedIn {
            CharalarmLogger.breadcrumb("声: 話しかけられて止めた played=\(playedCount)/\(chunks.count)")
            markInterrupted(playedText: chunks.prefix(playedCount).joined())
        } else {
            CharalarmLogger.breadcrumb("声: 流し終えた played=\(playedCount)/\(chunks.count)")
        }
    }

    /// 話しかけられて止めたので、キャラの発言を聞こえたところまでにする (相手に届いていない部分を覚えさせない)
    private func markInterrupted(playedText: String) {
        guard let index = chatMessages.lastIndex(where: { $0.role == ChatMessage.Role.assistant.rawValue }) else { return }
        let note = language == .english
            ? "(The user started talking here, so I stopped.)"
            : "（ここでユーザーが話し始めたので、途中で止めました）"
        chatMessages[index] = ChatMessage(role: .assistant, content: (playedText.isEmpty ? "" : playedText + "…") + note)
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

    /// ユーザーの話を聞いて会話するか。「今日の予定」は読み上げるだけで、マイクも使わない
    var listensToUser: Bool {
        if case .todaySchedule = topic { return false }
        return true
    }

    /// 画面を閉じたか、停止ボタンでこの流れを止めた
    private var isFinished: Bool {
        shouldDismiss || Task.isCancelled
    }

    /// ユーザーが話した回数
    private var userTurnCount: Int {
        chatMessages.filter { $0.role == ChatMessage.Role.user.rawValue }.count
    }

    private func shouldEndConversation() -> Bool {
        guard let startTime = conversationStartTime else { return false }
        return Date().timeIntervalSince(startTime) >= Constants.maxConversationDuration
    }

    // MARK: - Cleanup

    private func cleanupResources() {
        mainTask?.cancel()
        mainTask = nil

        if let engineConfigurationObserver {
            NotificationCenter.default.removeObserver(engineConfigurationObserver)
            self.engineConfigurationObserver = nil
        }

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
            if listensToUser {
                engine.inputNode.removeTap(onBus: 0)
            }
        }

        audioPlayer?.stop()
        audioPlayer = nil

        chatMessages.removeAll()
        textToSpeechRepository?.cleanupSynthesizer()
    }
}
