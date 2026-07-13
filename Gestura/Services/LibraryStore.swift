//
//  LibraryStore.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import Combine
import Foundation

class LibraryStore: ObservableObject {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @Published var favoriteIDs: Set<UInt64> = []
    @Published var recentlyPlayedIDs: [UInt64] = []

    // MARK: - SHARED

    static let shared = LibraryStore()

    // MARK: - PROPERTIES

    private let defaults = UserDefaults.standard
    private let favoritesKey = "favorites"
    private let recentlyPlayedKey = "recentlyPlayed"
    private let maxRecentCount = 20

    // MARK: - FUNCTIONS

    func loadFavorites() {
        let saved = defaults.array(forKey: favoritesKey) as? [UInt64] ?? []
        favoriteIDs = Set(saved)
    }

    func loadRecentlyPlayed() {
        recentlyPlayedIDs =
            defaults.array(forKey: recentlyPlayedKey) as? [UInt64] ?? []
    }

    func addFavorite(id: UInt64) {
        favoriteIDs.insert(id)
        defaults.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    func removeFavorite(id: UInt64) {
        favoriteIDs.remove(id)
        defaults.set(Array(favoriteIDs), forKey: favoritesKey)
    }
    func toggleFavorite(id: UInt64) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        defaults.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    func addToRecentlyPlayed(id: UInt64) {
        recentlyPlayedIDs.removeAll { $0 == id }
        recentlyPlayedIDs.insert(id, at: 0)
        if recentlyPlayedIDs.count > maxRecentCount {
            recentlyPlayedIDs = Array(recentlyPlayedIDs.prefix(maxRecentCount))
        }
        defaults.set(recentlyPlayedIDs, forKey: recentlyPlayedKey)
    }

    func isFavorite(id: UInt64) -> Bool {
        favoriteIDs.contains(id)
    }

    // MARK: - DESTRUCTIVE FUNCTIONS

    func clearFavorites() {
        favoriteIDs.removeAll()
        defaults.set([], forKey: favoritesKey)
    }

    func clearRecentlyPlayed() {
        recentlyPlayedIDs.removeAll()
        defaults.set([], forKey: recentlyPlayedKey)
    }

    // MARK: - INIT

    private init() {
        loadFavorites()
        loadRecentlyPlayed()
    }
}
