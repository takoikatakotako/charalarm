import Foundation

enum FileHandlerError: Error, LocalizedError {
    case encodeText
    case write
    case directoryNotFound
    case fileNotFound
    var errorDescription: String? {
        switch self {
        case .encodeText: return "Fail to Encode Text"
        case .write: return "Fail to Write"
        case .directoryNotFound: return "Directory Not Found"
        case .fileNotFound: return "File Not Found"
        }
    }
}
