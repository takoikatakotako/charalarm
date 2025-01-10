import Foundation

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

struct APIHeader {
    static let defaultHeader: [String: String] = ["Content-Type": "application/json"]

    static func createAuthorizationRequestHeader(userID: String, authToken: String) -> [String: String] {
        guard let authorization = "\(userID):\(authToken)".data(using: .utf8)?.base64EncodedString() else {
            fatalError()
        }
        var requestHeader = Self.defaultHeader
        requestHeader["Authorization"] = "Basic \(authorization)"
        return requestHeader
    }
}

struct APIRequest {
    static func createUrlRequest(baseUrl: String = EnvironmentVariableConfig.apiEndpoint, path: String, httpMethod: HttpMethod = .get, requestHeader: [String: String] = ["X-API-VERSION": "0", "Content-Type": "application/json"]) -> URLRequest {
        let url = URL(string: baseUrl + path)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.allHTTPHeaderFields = requestHeader
        return request
    }

    static func createUrlRequest<RequestBody: Encodable>(baseUrl: String = EnvironmentVariableConfig.apiEndpoint, path: String, httpMethod: HttpMethod = .get, requestHeader: [String: String] = ["X-API-VERSION": "0", "Content-Type": "application/json"], requestBody: RequestBody) -> URLRequest {
        let url = URL(string: EnvironmentVariableConfig.apiEndpoint + path)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.allHTTPHeaderFields = requestHeader
        if let httpBody = try? JSONEncoder().encode(requestBody) {
            request.httpBody = httpBody
        }
        return request
    }
}
