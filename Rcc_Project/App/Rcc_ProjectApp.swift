//
//  Rcc_ProjectApp.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI
import SwiftData

@main
struct Rcc_ProjectApp: App {

    @AppStorage("appTheme")  var appTheme:   String = "system"
    @UIApplicationDelegateAdaptor(AppDelegate.self) var application

    @StateObject private var lm = LocalizationManager()
    @StateObject private var session = SessionStore()

    var preferredScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isRestoring {
                    LaunchSplashView()
                } else if session.isLoggedIn {
                    if session.isAdmin {
                        AdminTabView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        ContentView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                } else {
                    NavigationStack {
                        LoginView()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: session.isLoggedIn)
            .animation(.easeInOut(duration: 0.3), value: session.isRestoring)
            .preferredColorScheme(preferredScheme)
            .environmentObject(lm)
            .environmentObject(session)
            .task { await session.restoreSession() }
            // Kicked off early so a token is usually ready by the time the user taps Sign In.
            .task { await PushNotificationManager.shared.requestAuthorizationAndRegister() }
        }
    }
}

/// Lightweight splash shown while a persisted session token is validated on launch.
/// Matches the auth header, so launching straight into the login screen is a
/// continuation rather than a cut.
private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            Color.dsBrand.ignoresSafeArea()

            VStack(spacing: DS.Space.lg) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                ProgressView().tint(.white)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading RCC Pay")
    }
}

class AppDelegate: NSObject,UIApplicationDelegate{
    static  let lockOrientation = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.lockOrientation
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationManager.shared.configureOnLaunch()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.setAPNSToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] APNs registration failed: \(error.localizedDescription)")
    }
}
