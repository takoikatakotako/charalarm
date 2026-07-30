#if DEBUG
import Foundation
import AVFoundation

/// 端末内 VOICEVOX 合成の疎通確認用 PoC。
/// 起動時に環境変数 `VOICEVOX_POC=1` が設定されているときのみ実行する。
/// フェーズ1（ずんだもん一言発話）の検証用。会話機能の実装が進んだら削除する。
enum VoicevoxPoC {
    private static var player: AVAudioPlayer?
    private static let repository: TextToSpeechRepository = VoicevoxRepository()

    static func runIfEnabled() {
        guard ProcessInfo.processInfo.environment["VOICEVOX_POC"] == "1" else { return }
        Task {
            do {
                NSLog("🟢VOICEVOX_POC start")
                try repository.setupSynthesizer()
                NSLog("🟢VOICEVOX_POC synthesizer ready")
                // 3 = ずんだもん ノーマル
                let wav = try await repository.synthesize(text: "こんにちは、ずんだもんなのだ。テスト発話なのだ。", styleId: 3)
                let header = String(bytes: wav.prefix(4), encoding: .ascii) ?? "----"
                NSLog("🟢VOICEVOX_POC synthesized bytes=\(wav.count) header=\(header)")
                guard header == "RIFF", wav.count > 44 else {
                    NSLog("🔴VOICEVOX_POC invalid WAV data")
                    return
                }
                player = try AVAudioPlayer(data: wav)
                let started = player?.play() ?? false
                NSLog("🟢VOICEVOX_POC playback started=\(started) duration=\(player?.duration ?? 0)")
            } catch {
                NSLog("🔴VOICEVOX_POC error: \(error.localizedDescription)")
            }
        }
    }
}
#endif
