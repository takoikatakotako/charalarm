import Foundation

enum CharalarmError: Error {
    case clientError
    case serverError
    case decode
    case encode
    /// API が 2xx 以外を返した。どの API が何を返したかをログで分かるようにする
    case httpStatus(path: String, statusCode: Int)
}

extension CharalarmError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .clientError:
            return "クライアントエラー。ネットワークを確認してください"
        case .serverError:
            return "サーバーエラー。サーバーからのデータ取得に失敗しました。"
        case .decode:
            return "クライアントエラー。データのデコードに失敗しました。"
        case .encode:
            return "クライアントエラー。データのエンコードに失敗しました。"
        case .httpStatus(_, let statusCode) where statusCode >= 500:
            return CharalarmError.serverError.errorDescription
        case .httpStatus:
            return CharalarmError.clientError.errorDescription
        }
    }
}

/// Crashlytics でまとまって見えるよう、HTTP のエラーは状態コードをエラーコードにする
extension CharalarmError: CustomNSError {
    static var errorDomain: String { "CharalarmError" }

    var errorCode: Int {
        switch self {
        case .clientError: return 1
        case .serverError: return 2
        case .decode: return 3
        case .encode: return 4
        case .httpStatus(_, let statusCode): return statusCode
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        case .httpStatus(let path, let statusCode):
            return ["path": path, "statusCode": statusCode]
        default:
            return [:]
        }
    }
}
