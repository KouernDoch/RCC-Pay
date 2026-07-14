import SwiftUI

/// Single source of truth for authentication. Wraps the backend auth calls, persists the
/// JWT via ``TokenStore``, and mirrors key facts into `@AppStorage`/`UserDefaults`
/// (`isLoggedIn`, `userRole`, `displayName`, `currentEmail`) so existing screens that read
/// those keys keep working unchanged.
@MainActor
final class SessionStore: ObservableObject {

    @Published private(set) var currentUser: UserDTO?
    /// True while we validate a persisted token on cold launch (show a splash).
    @Published private(set) var isRestoring: Bool = true

    var isLoggedIn: Bool { currentUser != nil }
    var isAdmin: Bool { currentUser?.role == .admin }
    var displayName: String { currentUser?.name ?? "" }

    init() {
        NotificationCenter.default.addObserver(
            forName: APIClient.unauthorizedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.signOut() }
        }
    }

    /// Called on launch: if a token is stored, confirm it's still valid by fetching the profile.
    func restoreSession() async {
        defer { isRestoring = false }
        guard TokenStore.token != nil else { return }
        do {
            let user = try await BackendAPI.currentUser()
            apply(user)
        } catch {
            // Token missing/expired/invalid — start signed out.
            TokenStore.token = nil
            currentUser = nil
            clearMirror()
        }
    }

    func login(email: String, password: String) async throws {
       
        let result = try await BackendAPI.login(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password)
        print("Data : ", result)
        TokenStore.token = result.accessToken
        
        apply(result.user)
    }

    func register(_ body: RegisterRequestDTO) async throws {
        let result = try await BackendAPI.register(body)
        TokenStore.token = result.accessToken
        apply(result.user)
    }

    /// Refresh the cached profile (e.g. after an edit).
    func refreshCurrentUser() async {
        guard isLoggedIn else { return }
        if let user = try? await BackendAPI.currentUser() {
            apply(user)
        }
    }

    func signOut() {
        TokenStore.token = nil
        currentUser = nil
        clearMirror()
    }

    // MARK: - AppStorage mirrors

    private func apply(_ user: UserDTO) {
        currentUser = user
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "isLoggedIn")
        defaults.set(user.role == .admin ? "admin" : "user", forKey: "userRole")
        defaults.set(user.name, forKey: "displayName")
        defaults.set(user.email, forKey: "currentEmail")
    }

    private func clearMirror() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
}
