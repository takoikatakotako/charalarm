import SwiftUI
import WebKit

/// VRM を three-vrm で描く WKWebView。ビューア（Resource ではなく VRMViewer フォルダ）はアプリに同梱する。
struct VRMWebView: UIViewRepresentable {
    enum Framing: String {
        /// 胸から上
        case bust
        /// 全身
        case full
    }

    /// 端末内の VRM ファイル（同梱かキャッシュ）
    let modelFileURL: URL
    var framing: Framing = .bust
    var onLoaded: () -> Void = {}
    var onError: (String) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoaded: onLoaded, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let schemeHandler = VRMSchemeHandler(modelFileURL: modelFileURL)
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: VRMSchemeHandler.scheme)
        configuration.userContentController.add(context.coordinator, name: "vrm")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        // safe area の分だけ中身を寄せない（寄せると、画面の下の端の手前で体が切れる）
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        #if DEBUG
        webView.isInspectable = true
        #endif

        var components = URLComponents()
        components.scheme = VRMSchemeHandler.scheme
        components.host = VRMSchemeHandler.host
        components.path = "/index.html"
        components.queryItems = [
            URLQueryItem(name: "model", value: VRMSchemeHandler.modelPath),
            URLQueryItem(name: "framing", value: framing.rawValue)
        ]
        if let url = components.url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "vrm")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let onLoaded: () -> Void
        private let onError: (String) -> Void

        init(onLoaded: @escaping () -> Void, onError: @escaping (String) -> Void) {
            self.onLoaded = onLoaded
            self.onError = onError
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else {
                return
            }
            switch type {
            case "loaded":
                onLoaded()
            case "error":
                let detail = body["message"] as? String ?? ""
                CharalarmLogger.error("Failed to load VRM: \(detail)")
                onError(detail)
            default:
                break
            }
        }
    }
}

/// charalarm-vrm://app/ 以下で、同梱のビューアとモデルを返す。
/// file:// だと JavaScript のモジュールが読めないため、独自のスキームにしている。
final class VRMSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "charalarm-vrm"
    static let host = "app"
    static let modelPath = "/model.vrm"

    private let modelFileURL: URL
    private let viewerDirectoryURL: URL?

    init(modelFileURL: URL) {
        self.modelFileURL = modelFileURL
        self.viewerDirectoryURL = Bundle.main.url(forResource: "VRMViewer", withExtension: nil)
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let fileURL = fileURL(for: url.path),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": Self.mimeType(for: fileURL), "Content-Length": "\(data.count)"]
        )
        if let response {
            urlSchemeTask.didReceive(response)
        }
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func fileURL(for path: String) -> URL? {
        if path == Self.modelPath {
            return modelFileURL
        }
        guard let viewerDirectoryURL else {
            return nil
        }
        // VRMViewer フォルダの外は返さない
        let fileURL = viewerDirectoryURL.appendingPathComponent(path).standardizedFileURL
        guard fileURL.path.hasPrefix(viewerDirectoryURL.standardizedFileURL.path + "/") else {
            return nil
        }
        return fileURL
    }

    private static func mimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "vrm", "glb": return "model/gltf-binary"
        default: return "application/octet-stream"
        }
    }
}
