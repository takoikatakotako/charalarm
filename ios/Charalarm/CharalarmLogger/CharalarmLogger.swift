import Foundation
import DatadogCore
import DatadogLogs

struct CharalarmLogger {
    static func debug(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        log(level: .debug, message: message, error: error, attributes: attributes)
    }

    static func info(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        log(level: .info, message: message, error: error, attributes: attributes)
    }

    static func error(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        log(level: .error, message: message, error: error, attributes: attributes)
    }

    static func critical(_ message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        log(level: .critical, message: message, error: error, attributes: attributes)
    }

    private static func log(level: LogLevel, message: String, error: Error? = nil, attributes: [String: String]? = nil) {
        let logger = Logger.create(
            with: Logger.Configuration(
                name: "charalarm",
                networkInfoEnabled: true,
                remoteLogThreshold: .info,
                consoleLogFormat: .shortWith(prefix: "[iOS App] ")
            )
        )

        switch level {
        case .debug:
            logger.debug(message, error: error, attributes: attributes)
        case .info:
            logger.info(message, error: error, attributes: attributes)
        case .notice:
            logger.notice(message, error: error, attributes: attributes)
        case .warn:
            logger.warn(message, error: error, attributes: attributes)
        case .error:
            logger.error(message, error: error, attributes: attributes)
        case .critical:
            logger.critical(message, error: error, attributes: attributes)
        }
    }
}
