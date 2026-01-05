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
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
    
    init() {
            // Force Light Mode for all windows
            UIView.appearance().overrideUserInterfaceStyle = .light
        }

    @UIApplicationDelegateAdaptor(AppDelegate.self) var application
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
//        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject,UIApplicationDelegate{
    static  let lockOrientation = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.lockOrientation
    }
}
