//
//  LibraryStore.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import Combine
import Foundation
internal import MusicKit

class LibraryStore: ObservableObject {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @Published var favoriteIDs: [MusicItemID] = []
    @Published var recentlyPlayedIDs: [MusicItemID] = []

    // MARK: - SHARED

    static let shared = LibraryStore()

    // MARK: - PROPERTIES

    private let defaults = UserDefaults.standard
    private let favoritesKey = "favorites"
    private let recentlyPlayedKey = "recentlyPlayed"
    private let maxRecentCount = 20

    // MARK: - FUNCTIONS

    func loadFavorites() {
        let saved = defaults.stringArray(forKey: favoritesKey) ?? []
        favoriteIDs = saved.map { MusicItemID($0) }
    }

    func loadRecentlyPlayed() {
        let saved = defaults.stringArray(forKey: recentlyPlayedKey) ?? []
        recentlyPlayedIDs = saved.map { MusicItemID($0) }
    }

    func addFavorite(id: MusicItemID) {
        guard !favoriteIDs.contains(id) else { return }
        favoriteIDs.insert(id, at: 0)
        defaults.set(favoriteIDs.map(\.rawValue), forKey: favoritesKey)
    }

    func removeFavorite(id: MusicItemID) {
        favoriteIDs.removeAll { $0 == id }
        defaults.set(favoriteIDs.map(\.rawValue), forKey: favoritesKey)
    }

    func toggleFavorite(id: MusicItemID) {
        if isFavorite(id: id) {
            removeFavorite(id: id)
        } else {
            addFavorite(id: id)
        }
    }

    func addToRecentlyPlayed(id: MusicItemID) {
        recentlyPlayedIDs.removeAll { $0 == id }
        recentlyPlayedIDs.insert(id, at: 0)
        if recentlyPlayedIDs.count > maxRecentCount {
            recentlyPlayedIDs = Array(recentlyPlayedIDs.prefix(maxRecentCount))
        }
        defaults.set(recentlyPlayedIDs.map(\.rawValue), forKey: recentlyPlayedKey)
    }

    func isFavorite(id: MusicItemID) -> Bool {
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
