import Foundation

struct APIClient {
    func downloadFile(url: URL) async throws -> Data {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.get.rawValue
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            throw CharalarmError.clientError
        }

        guard urlResponse.statusCode == 200 else {
            throw CharalarmError.clientError
        }

        return data
    }

    func request<ResponseType: Decodable>(url: URL, httpMethod: HttpMethod, requestHeader: [String: String], requestBody: Encodable?) async throws -> ResponseType {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = requestHeader
        if let requestBody = requestBody, let httpBody = try? JSONEncoder().encode(requestBody) {
            urlRequest.httpBody = httpBody
        }

        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)

        CharalarmLogger.debug(urlRequest.curlString)

        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            throw CharalarmError.clientError
        }

        guard (200 ... 299) ~= urlResponse.statusCode else {
            if (try? JSONDecoder().decode(MessageResponse.self, from: data)) == nil {
                throw CharalarmError.clientError
            }
            throw CharalarmError.clientError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(ResponseType.self, from: data)
        return response
    }

    // レスポンスが不要の場合
    func request(url: URL, httpMethod: HttpMethod, requestHeader: [String: String], requestBody: Encodable?) async throws {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = requestHeader
        if let requestBody = requestBody, let httpBody = try? JSONEncoder().encode(requestBody) {
            urlRequest.httpBody = httpBody
        }

        let (_, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            throw CharalarmError.clientError
        }

        guard (200 ... 299) ~= urlResponse.statusCode else {
            throw CharalarmError.clientError
        }
    }
}
