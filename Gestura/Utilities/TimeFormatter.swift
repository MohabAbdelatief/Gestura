//
//  TimeFormatter.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 24/04/2026.
//

import Foundation

// MARK: - HELPERS

func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
