import Foundation
import UIKit
import UserNotifications

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/// Owns Firebase Cloud Messaging for the app: configures Firebase on launch, registers with
/// APNs, and caches the latest FCM registration token so auth calls can attach it.
///
/// The Firebase bits are compiled only when the SDK is present (`canImport`). Without it the
/// manager still builds and simply reports no token, which callers already treat as "send
/// login without an fcmToken".
final class PushNotificationManager: NSObject, ObservableObject {

    static let shared = PushNotificationManager()

    /// Latest token handed to us by Firebase. Updated on refresh, so it survives token rotation.
    @Published private(set) var fcmToken: String?

    /// How long ``currentToken()`` waits for Firebase before giving up. Login must not block on
    /// push registration, so we fall through rather than hang.
    private let tokenTimeout: Duration = .seconds(3)

    private override init() { super.init() }

    // MARK: - Launch

    /// Call once from the app delegate's `didFinishLaunchingWithOptions`.
    func configureOnLaunch() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif
        UNUserNotificationCenter.current().delegate = self
    }

    /// Ask for notification permission and register with APNs. Safe to call more than once.
    func requestAuthorizationAndRegister() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false

        // Register regardless of the alert permission: a device token still enables silent
        // pushes, and the user can flip alerts on later without another launch.
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }

        if !granted {
            print("[Push] Notification authorization not granted.")
        }
    }

    /// Store the APNs device token so FCM can mint a registration token against it.
    func setAPNSToken(_ deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    // MARK: - Token access

    /// The freshest FCM token available, or `nil` if Firebase can't produce one in time
    /// (SDK absent, APNs token not yet issued, no network, simulator without push support).
    func currentToken() async -> String? {
        #if canImport(FirebaseMessaging)
        if let cached = fcmToken { return cached }

        let token = await withTaskGroup(of: String?.self) { group in
            group.addTask { try? await Messaging.messaging().token() }
            group.addTask { [tokenTimeout] in
                try? await Task.sleep(for: tokenTimeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }

        if let token { await MainActor.run { self.fcmToken = token } }
        return token
        #else
        return nil
        #endif
    }

    /// Drop the token on sign-out so the next user doesn't inherit this device's registration.
    func clearToken() async {
        #if canImport(FirebaseMessaging)
        try? await Messaging.messaging().deleteToken()
        #endif
        await MainActor.run { self.fcmToken = nil }
    }
}

#if canImport(FirebaseMessaging)
extension PushNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in self.fcmToken = fcmToken }
    }
}
#endif

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    /// Show pushes that arrive while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
