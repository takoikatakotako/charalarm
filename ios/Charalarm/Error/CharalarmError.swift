import Foundation

enum CharalarmError: Error {
    case clientError
    case serverError
    case decode
    case encode
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
        }
    }
}
