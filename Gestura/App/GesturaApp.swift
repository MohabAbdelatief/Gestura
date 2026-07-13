//
//  GesturaApp.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//

import SwiftData
import SwiftUI

@main
struct GesturaApp: App {
    // MARK: - VIEW

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Playlist.self)
    }
}
