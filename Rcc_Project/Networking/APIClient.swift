import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Thin async/await HTTP client for the RCC-PAY backend. Handles bearer-token
/// injection, JSON (de)coding of the `GenericApiResponse` envelope, and error mapping.
struct APIClient {

    static let shared = APIClient()

    /// Posted whenever the backend rejects the token (HTTP 401) so the session can sign out.
    static let unauthorizedNotification = Notification.Name("APIClient.unauthorized")

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Convenience verbs

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        try await request(path, method: .get, query: query, bodyData: nil)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: .post, bodyData: try encoder.encode(body))
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: .put, bodyData: try encoder.encode(body))
    }

    /// PATCH / POST with no request body (e.g. mark-notification-read).
    func send<T: Decodable>(_ path: String, method: HTTPMethod) async throws -> T {
        try await request(path, method: method, bodyData: nil)
    }

    /// POST with a body but a response payload we don't care about.
    @discardableResult
    func postVoid<B: Encodable>(_ path: String, body: B) async throws -> Bool {
        let _: EmptyPayload = try await request(path, method: .post, bodyData: try encoder.encode(body))
        return true
    }

    /// PUT with a body but no meaningful response payload (e.g. change password).
    @discardableResult
    func putVoid<B: Encodable>(_ path: String, body: B) async throws -> Bool {
        let _: EmptyPayload = try await request(path, method: .put, bodyData: try encoder.encode(body))
        return true
    }

    /// DELETE with no response payload.
    @discardableResult
    func delete(_ path: String) async throws -> Bool {
        let _: EmptyPayload = try await request(path, method: .delete, bodyData: nil)
        return true
    }

    // MARK: - Core

    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        query: [URLQueryItem]? = nil,
        bodyData: Data?
    ) async throws -> T {
        var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false)
        
        if let query, !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            throw APIError.server(status: -1, message: "Invalid request URL")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bodyData {
            req.httpBody = bodyData
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = TokenStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: -1, message: "No HTTP response")
        }

        if http.statusCode == 401 {
            await MainActor.run {
                NotificationCenter.default.post(name: APIClient.unauthorizedNotification, object: nil)
            }
            throw APIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = decodeErrorMessage(from: data) ?? "Request failed (\(http.statusCode))"
            throw APIError.server(status: http.statusCode, message: message)
        }

        // Empty body (rare) but expected payload → treat EmptyPayload as success.
        if data.isEmpty, T.self == EmptyPayload.self, let empty = EmptyPayload() as? T {
            return empty
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
            if let payload = envelope.payload {
                return payload
            }
            if let empty = EmptyPayload() as? T {
                return empty
            }
            throw APIError.decoding(
                underlying: DecodingError.valueNotFound(
                    T.self,
                    .init(codingPath: [], debugDescription: "Missing payload")))
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        if let body = try? decoder.decode(APIErrorBody.self, from: data) {
            if let fieldErrors = body.fieldErrors, !fieldErrors.isEmpty {
                return fieldErrors.map { "\($0.value)" }.joined(separator: "\n")
            }
            if let message = body.message, !message.isEmpty {
                return message
            }
        }
        // Fall back to the envelope message shape.
        if let env = try? decoder.decode(APIEnvelope<EmptyPayload>.self, from: data),
           let message = env.message, !message.isEmpty {
            return message
        }
        return nil
    }
}

/// Placeholder payload for endpoints that return no meaningful data.
struct EmptyPayload: Decodable {
    init() {}
    init(from decoder: Decoder) throws {}
}
