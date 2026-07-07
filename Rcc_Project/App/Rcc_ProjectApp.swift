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
        }
    }
}

/// Lightweight splash shown while a persisted session token is validated on launch.
private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.30, blue: 0.88),
                         Color(red: 0.22, green: 0.52, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                ProgressView().tint(.white)
            }
        }
    }
}

class AppDelegate: NSObject,UIApplicationDelegate{
    static  let lockOrientation = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.lockOrientation
    }
}
