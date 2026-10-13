import Foundation

/// キャラの 3D モデル（VRM）のファイルを用意する。
/// アプリに同梱したモデル（Resource/{charaID}/{ファイル名}）があればそれを使い、
/// なければダウンロードして Caches に置く。モデルを更新するときはサーバで別のファイル名にする。
struct VRMModelRepository {
    private let fileManager = FileManager.default

    func modelFileURL(charaID: String, modelFileURL remoteURL: URL) async throws -> URL {
        let fileName = remoteURL.lastPathComponent
        if let bundled = bundledModelFileURL(charaID: charaID, fileName: fileName) {
            return bundled
        }

        let cached = try cacheFileURL(charaID: charaID, fileName: fileName)
        if fileManager.fileExists(atPath: cached.path) {
            return cached
        }

        let data = try await APIClient().downloadFile(url: remoteURL)
        try fileManager.createDirectory(at: cached.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: cached, options: .atomic)
        return cached
    }

    /// アプリに同梱したモデル。
    func bundledModelFileURL(charaID: String, fileName: String) -> URL? {
        Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Resource/\(charaID)")
    }

    private func cacheFileURL(charaID: String, fileName: String) throws -> URL {
        guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw FileHandlerError.directoryNotFound
        }
        return caches
            .appendingPathComponent("vrm", isDirectory: true)
            .appendingPathComponent(charaID, isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
