import AVFoundation

/// キャラの声に合わせた口の開き具合。声を流す直前に音声から作り、3D のビューアにまとめて渡す。
/// 母音の形までは出さず、声の大きさで「あ」の口を開け閉めする
struct VRMMouthTrack: Equatable {
    /// 1 秒あたりのコマ数
    static let framesPerSecond = 30

    /// 流すたびに違うものとして扱う（同じ文を続けて流しても、口を動かし直す）
    let id = UUID()
    /// コマごとの口の開き具合 (0〜1)
    let levels: [Float]

    init(levels: [Float]) {
        self.levels = levels
    }

    init(buffer: AVAudioPCMBuffer) {
        self.init(levels: Self.levels(of: buffer))
    }

    /// 音声ファイルのデータ (caf・wav など) から作る。読めなければ nil
    init?(audioData: Data) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("mouth-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        guard (try? audioData.write(to: fileURL)) != nil,
              let file = try? AVAudioFile(forReading: fileURL),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil else {
            return nil
        }
        self.init(buffer: buffer)
    }

    /// コマごとの音の大きさを、その声のいちばん大きいところを 1 として並べる。
    /// 小さい音（息や残響）では口を開けない
    static func levels(of buffer: AVAudioPCMBuffer) -> [Float] {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return [] }
        let samplesPerFrame = max(1, Int(buffer.format.sampleRate) / framesPerSecond)
        let count = Int(buffer.frameLength)
        var rms: [Float] = []
        var start = 0
        while start < count {
            let end = min(start + samplesPerFrame, count)
            var sum: Float = 0
            for index in start..<end {
                sum += samples[index] * samples[index]
            }
            rms.append((sum / Float(end - start)).squareRoot())
            start = end
        }
        // いちばん大きいところではなく、上から 1 割あたりを基準にする（一瞬の大きな音に引っぱられない）
        let reference = rms.sorted()[max(0, Int(Float(rms.count) * 0.9) - 1)]
        guard reference > 0.000_1 else { return rms.map { _ in 0 } }
        return rms.map { value in
            let level = min(value / reference, 1)
            return level < 0.15 ? 0 : level.squareRoot()
        }
    }

    /// ビューアに渡す JavaScript
    var script: String {
        let values = levels.map { String(format: "%.2f", $0) }.joined(separator: ",")
        return "startSpeaking([\(values)], \(Self.framesPerSecond))"
    }
}
