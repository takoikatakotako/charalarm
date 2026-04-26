import Foundation
import FirebaseCrashlytics

struct CharalarmLogger {
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
