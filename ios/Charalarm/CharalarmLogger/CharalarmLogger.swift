import Foundation
import FirebaseCrashlytics
import os

/// ログ。info 以上は Crashlytics にも送り、debug は端末のログ（Xcode・Console.app）にだけ出す。
struct CharalarmLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Charalarm", category: "app")

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    /// 流れの区切り（電話に出た・返事を作った・声を流した など）。端末のログと Crashlytics に残し、
    /// エラーやクラッシュが起きたとき、どこまで進んでいたかが分かるようにする。
    /// 会話の中身や予定などの個人情報は入れず、段階・文字数・状態コードくらいにする。
    static func breadcrumb(_ message: String) {
        logger.info("\(message, privacy: .public)")
        Crashlytics.crashlytics().log(message)
    }

    static func info(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        record(level: "info", message: message, error: error, attributes: attributes)
    }

    static func error(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        record(level: "error", message: message, error: error, attributes: attributes)
    }

    static func critical(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        record(level: "critical", message: message, error: error, attributes: attributes)
    }

    private static func record(level: String, message: String, error: Error?, attributes: [String: String]?) {
        logger.error("[\(level, privacy: .public)] \(message, privacy: .public) \(error.map { String(describing: $0) } ?? "", privacy: .public)")
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.log("[\(level)] \(message)")
        if let attributes = attributes {
            crashlytics.setCustomKeysAndValues(attributes)
        }
        if let error = error {
            crashlytics.record(error: error)
        } else {
            let nsError = NSError(
                domain: "CharalarmLogger",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
            crashlytics.record(error: nsError)
        }
    }
}
