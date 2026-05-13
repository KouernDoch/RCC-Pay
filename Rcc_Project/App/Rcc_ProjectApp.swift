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
    @AppStorage("isLoggedIn") var isLoggedIn: Bool   = false
    @AppStorage("userRole")   var userRole:   String = "user"
    @UIApplicationDelegateAdaptor(AppDelegate.self) var application

    @StateObject private var lm = LocalizationManager()

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
                if isLoggedIn {
                    if userRole == "admin" {
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
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isLoggedIn)
            .preferredColorScheme(preferredScheme)
            .environmentObject(lm)
        }
    }
}

class AppDelegate: NSObject,UIApplicationDelegate{
    static  let lockOrientation = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.lockOrientation
    }
}
