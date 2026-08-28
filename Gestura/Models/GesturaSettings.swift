//
//  GesturaSettings.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 28/08/2026.
//

import Foundation

/// Single source of truth for the `gesturaEnabled` preference. Four views read
/// this key via `@AppStorage`; keeping the key and its default here stops them
/// from drifting apart.
enum GesturaSettings {
    static let enabledKey = "gesturaEnabled"
    static let enabledDefault = true

    /// Reads the preference outside a SwiftUI view — e.g. to pick the launch
    /// tab, where `@AppStorage` isn't available in a property initializer.
    ///
    /// Deliberately not `UserDefaults.bool(forKey:)`: that returns `false` for
    /// an absent key, which would silently override `enabledDefault`.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool
            ?? enabledDefault
    }
}
