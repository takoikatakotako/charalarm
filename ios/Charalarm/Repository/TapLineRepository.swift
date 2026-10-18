import Foundation

/// トップでキャラをタップしたときのセリフ。
/// セリフの一覧はトップを開いたときに API から取り直し、ボイスは流すときにダウンロードして端末（Caches）に取っておく。
/// 全部を先にダウンロードしないのは、言語 × セリフで数百個あり、1日に聞くのは数個だけなので。
struct TapLineRepository {
    private let apiRepository = APIRepository()

    /// API からセリフの一覧を取り、端末にも取っておく（通信できないときに使う）
    func fetchLines(charaID: String) async throws -> [TapLine] {
        let lines = try await apiRepository.fetchCharacter(charaID: charaID).tapLines
        if let data = try? JSONEncoder().encode(lines) {
            try? data.write(to: try linesFileURL(charaID: charaID), options: .atomic)
        }
        return lines
    }

    /// 前に取っておいたセリフの一覧
    func cachedLines(charaID: String) -> [TapLine] {
        guard let url = try? linesFileURL(charaID: charaID),
              let data = try? Data(contentsOf: url),
              let lines = try? JSONDecoder().decode([TapLine].self, from: data) else {
            return []
        }
        return lines
    }

    /// ボイスを端末に取ってあるか
    func hasCachedVoice(charaID: String, line: TapLine) -> Bool {
        guard let url = try? voiceFileURL(charaID: charaID, line: line) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// ボイス。端末になければダウンロードして取っておく
    func voice(charaID: String, line: TapLine) async throws -> Data {
        let localURL = try voiceFileURL(charaID: charaID, line: line)
        if let data = try? Data(contentsOf: localURL) {
            return data
        }
        guard let remoteURL = line.voiceFileURL else {
            throw URLError(.fileDoesNotExist)
        }
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        try? data.write(to: localURL, options: .atomic)
        return data
    }

    /// 次に流しそうなボイスを先にダウンロードしておく（失敗してもかまわない）
    func prefetch(charaID: String, lines: [TapLine]) async {
        for line in lines where !hasCachedVoice(charaID: charaID, line: line) {
            _ = try? await voice(charaID: charaID, line: line)
        }
    }

    private func directoryURL(charaID: String) throws -> URL {
        let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("TapLines", isDirectory: true)
            .appendingPathComponent(charaID, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func linesFileURL(charaID: String) throws -> URL {
        try directoryURL(charaID: charaID).appendingPathComponent("lines.json")
    }

    private func voiceFileURL(charaID: String, line: TapLine) throws -> URL {
        try directoryURL(charaID: charaID).appendingPathComponent(line.voiceFileName)
    }
}
