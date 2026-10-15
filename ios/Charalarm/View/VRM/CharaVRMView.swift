import SwiftUI

/// キャラの VRM を表示する。モデルは同梱のものか、ダウンロードしてキャッシュしたものを使う。
struct CharaVRMView: View {
    let charaID: String
    /// サーバの modelFileURL。ファイル名が同梱のものと同じなら、ダウンロードしない
    let modelFileURL: URL
    var framing: VRMWebView.Framing = .bust

    @State private var localModelFileURL: URL?
    @State private var isLoaded = false
    @State private var failed = false

    var body: some View {
        ZStack {
            if let localModelFileURL {
                VRMWebView(
                    modelFileURL: localModelFileURL,
                    framing: framing,
                    onLoaded: { isLoaded = true },
                    onError: { _ in failed = true }
                )
                .opacity(isLoaded ? 1 : 0)
            }

            if failed {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Color.secondary)
            } else if !isLoaded {
                ProgressView()
            }
        }
        .task(id: modelFileURL) {
            do {
                localModelFileURL = try await VRMModelRepository().modelFileURL(charaID: charaID, modelFileURL: modelFileURL)
            } catch {
                CharalarmLogger.error("Failed to prepare VRM, file: \(#file), line: \(#line)", error: error)
                failed = true
            }
        }
    }
}
