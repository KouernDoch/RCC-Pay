//
//  LocalizationManager.swift
//  RCC Pay
//

import Foundation
import Combine
import SwiftUI

/// Observes the "appLanguage" key in UserDefaults (set by @AppStorage in ProfileView)
/// and exposes a subscript that loads the correct string from the matching .lproj bundle.
class LocalizationManager: ObservableObject {

    @Published private(set) var language: String

    private var cancellable: AnyCancellable?

    init() {
        language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"

        // React whenever any @AppStorage / UserDefaults write changes the key
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
                guard self?.language != lang else { return }
                self?.language = lang
            }
    }

    // MARK: - Lookup

    /// Primary access point: lm["key"]
    subscript(_ key: String) -> String { localized(key) }

    func localized(_ key: String) -> String {
        guard
            let path   = Bundle.main.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
