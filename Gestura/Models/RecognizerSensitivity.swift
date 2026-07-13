//
//  RecognizerSensitivity.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 25/05/2026.
//

import Foundation

enum RecognizerSensitivity: String, CaseIterable {
    static let appStorageKey = "recognizerSensitivity"

    // MARK: - CASES
    case relaxed
    case standard
    case snappy

    struct Settings {
        let holdDuration: TimeInterval
        let confidenceThreshold: Double
        let cooldown: TimeInterval
    }

    // MARK: - COMPUTED PROPERTIES

    var settings: Settings {
        switch self {
        case .relaxed:
            return Settings(
                holdDuration: 0.7,
                confidenceThreshold: 0.9,
                cooldown: 2.5
            )
        case .standard:
            return Settings(
                holdDuration: 0.45,
                confidenceThreshold: 0.8,
                cooldown: 1.5
            )
        case .snappy:
            return Settings(
                holdDuration: 0.2,
                confidenceThreshold: 0.7,
                cooldown: 0.8
            )
        }
    }

    var displayName: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .standard: return "Standard"
        case .snappy: return "Snappy"
        }
    }

    static func current() -> RecognizerSensitivity {
        let rawValue =
            UserDefaults.standard.string(forKey: appStorageKey)
            ?? RecognizerSensitivity.standard.rawValue
        return RecognizerSensitivity(rawValue: rawValue) ?? .standard
    }
}
