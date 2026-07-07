import Foundation

/// Errors surfaced by ``APIClient``. `message` is safe to show to the user.
enum APIError: LocalizedError {
    /// Non-2xx response. `status` is the HTTP code; `message` comes from the backend `ErrorResponse`.
    case server(status: Int, message: String)
    /// The session token is missing/expired (HTTP 401). Callers should sign the user out.
    case unauthorized
    /// Could not reach the backend at all (offline, wrong host, server down).
    case network(underlying: Error)
    /// Response body could not be decoded into the expected shape.
    case decoding(underlying: Error)

    var errorDescription: String? {
        switch self {
        case let .server(_, message):
            return message
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .network:
            return "Cannot reach the server. Check that the backend is running and try again."
        case .decoding:
            return "The server returned an unexpected response."
        }
    }
}
