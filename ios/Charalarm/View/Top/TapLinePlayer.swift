import AVFoundation
import Foundation

/// トップでキャラをタップしたときのセリフを流す。
/// セリフの一覧はトップを開いたときに API から取り直し、ボイスは流すときにダウンロードして端末に取っておく（TapLineRepository）。
@MainActor @Observable final class TapLinePlayer {
    /// 流したセリフ（吹き出しに少しのあいだ出す）
    private(set) var text: String?

    private var lines: [TapLine] = []
    private var charaID: String?
    /// 最近流したセリフ（続けて同じものを流さない）
    private var recentLines: [TapLine] = []
    private var audioPlayer: AVAudioPlayer?
    private var hideTextTask: Task<Void, Never>?
    private var restoreCategoryTask: Task<Void, Never>?
    private let repository = TapLineRepository()
    private let fileRepository: FileRepositoryProtocol = FileRepository()

    /// このキャラのセリフがあるか（なければ表情のボイスを流す）
    func hasLines(charaID: String) -> Bool {
        self.charaID == charaID && !lines.isEmpty
    }

    /// セリフを、端末に取っておいたもの → API の順に読み、次に流しそうなボイスを先にダウンロードしておく
    func load(charaID: String, language: ConversationLanguage) {
        if self.charaID != charaID {
            self.charaID = charaID
            lines = repository.cachedLines(charaID: charaID)
            recentLines = []
        }
        Task {
            do {
                let fetched = try await repository.fetchLines(charaID: charaID)
                guard self.charaID == charaID else { return }
                lines = fetched
            } catch {
                CharalarmLogger.error("タップのセリフを取れませんでした", error: error)
            }
            await repository.prefetch(charaID: charaID, lines: nextCandidates(count: 3, language: language))
        }
    }

    /// 今の日時に合うセリフを流す（クリスマスなど条件つきを優先し、最近流したものは避ける）。
    /// ボイスがなければダウンロードし、通信できなければ端末に取ってあるセリフから選ぶ
    func play(charaID: String, language: ConversationLanguage) {
        let lines = TapLineSelector.lines(lines, in: language)
        guard let line = pick(from: lines) else { return }

        Task {
            var playing = line
            var data = try? await repository.voice(charaID: charaID, line: line)
            if data == nil {
                let cached = lines.filter { repository.hasCachedVoice(charaID: charaID, line: $0) }
                if let fallback = TapLineSelector.select(from: cached, recent: recentLines) {
                    playing = fallback
                    data = try? await repository.voice(charaID: charaID, line: fallback)
                }
            }
            guard let data else {
                CharalarmLogger.error("タップのセリフのボイスを読めませんでした")
                return
            }
            playVoice(data)
            show(playing.text)
            // 次の分を先にダウンロードしておく
            await repository.prefetch(charaID: charaID, lines: nextCandidates(count: 2, language: language))
        }
    }

    /// 古いデータ: キャラを選んだときに端末にダウンロードしたボイスのセリフを流す
    func playDownloaded(charaID: String, lines: [TapLine], language: ConversationLanguage) {
        let lines = TapLineSelector.lines(lines, in: language)
        guard let line = pick(from: lines) else { return }
        do {
            playVoice(try fileRepository.loadData(directoryName: charaID, fileName: line.voiceFileName))
            show(line.text)
        } catch {
            CharalarmLogger.error("タップのセリフのボイスを読めませんでした", error: error)
        }
    }

    /// ボイスを流す（表情のボイスにも使う）。
    /// うっかり触ったときに鳴らないよう、マナーモードのときは鳴らさない（吹き出しのセリフは出す）。
    /// 設定で「マナーモードでも声を出す」をオンにしていれば鳴らす
    func playVoice(_ data: Data) {
        // 電話のあいだは、電話の音声カテゴリを変えない
        guard AnsweredCallStore.shared.call == nil else { return }
        setAudioCategory(UserDefaultsRepository().getTapVoiceInSilentMode() ? .playback : .ambient)
        audioPlayer = try? AVAudioPlayer(data: data)
        audioPlayer?.play()

        // 流し終えたら、アプリのほかの音（着信音など）のためにマナーモードでも鳴る設定に戻す
        restoreCategoryTask?.cancel()
        let duration = audioPlayer?.duration ?? 0
        restoreCategoryTask = Task {
            try? await Task.sleep(for: .seconds(duration + 0.3))
            // バックグラウンドで待っているあいだに電話に出ていたら、電話の音声カテゴリを上書きしない
            guard !Task.isCancelled, AnsweredCallStore.shared.call == nil else { return }
            self.setAudioCategory(.playback)
        }
    }

    private func setAudioCategory(_ category: AVAudioSession.Category) {
        do {
            try AVAudioSession.sharedInstance().setCategory(category, options: .mixWithOthers)
        } catch {
            CharalarmLogger.error("オーディオセッションを切り替えられませんでした", error: error)
        }
    }

    private func pick(from lines: [TapLine]) -> TapLine? {
        guard let line = TapLineSelector.select(from: lines, recent: recentLines) else { return nil }
        recentLines = Array((recentLines + [line]).suffix(min(5, max(lines.count - 1, 0))))
        return line
    }

    /// 次に流しそうなセリフ（今の言語・日時に合うもの）
    private func nextCandidates(count: Int, language: ConversationLanguage) -> [TapLine] {
        let lines = TapLineSelector.lines(lines, in: language)
        var picked: [TapLine] = []
        for _ in 0..<count {
            guard let line = TapLineSelector.select(from: lines, recent: recentLines + picked) else { break }
            if !picked.contains(line) {
                picked.append(line)
            }
        }
        return picked
    }

    /// 吹き出しにセリフを出す。ボイスを流し終えて少ししてから消す（流しているあいだは消さない）。
    /// 短いセリフも読めるよう 1.5 秒は出す。ボイスが読めなかったときは5秒
    private func show(_ text: String) {
        self.text = text
        hideTextTask?.cancel()
        let duration = audioPlayer.map { max($0.duration + 0.2, 1.5) } ?? 5
        hideTextTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self.text = nil
        }
    }
}
