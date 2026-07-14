import Foundation

/// Central configuration for talking to the RCC-PAY backend.
///
/// The simulator can reach a backend running on the same Mac via `localhost`.
/// When running on a **physical device**, change `host` to your Mac's LAN IP
/// (e.g. `http://192.168.1.20:8080`) — the device cannot see the Mac's localhost.
enum APIConfig {

    /// Base origin of the backend, without the `/api` suffix.
    static let host = "http://157.10.72.79:8888"

    /// Base URL including the `/api` context path all controllers share.
    static var baseURL: URL { URL(string: "\(host)/api")! }
}
