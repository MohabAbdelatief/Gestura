//
//  MusicLibraryViewModel.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 15/05/2026.
//

import Combine
import Foundation

@MainActor
class MusicLibrary: ObservableObject {
    // MARK: - PROPERTIES

    private let libraryStore = LibraryStore.shared
    private let musicService = MusicService.shared

    // MARK: - PUBLISHED PROPERTIES

    @Published var permissionDenied: Bool = false
    // True once an authorized fetch has completed, so the UI can tell
    // "still loading" from "loaded but empty".
    @Published private(set) var hasLoaded: Bool = false
    @Published private(set) var songs: [Track] = [] {
        didSet {
            tracksByID = Dictionary(
                songs.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }

    private(set) var tracksByID: [UInt64: Track] = [:]

    // MARK: - COMPUTED PROPERTIES

    var recentlyPlayedTracks: [Track] {
        libraryStore.recentlyPlayedIDs.compactMap { id in
            tracksByID[id]
        }
    }

    var favoriteTracks: [Track] {
        libraryStore.favoriteIDs.compactMap { id in
            tracksByID[id]
        }
    }

    var artists: [Artist] {
        return Dictionary(grouping: songs, by: { $0.artist })
            .map { Artist(name: $0.key, tracks: $0.value) }
            .sorted { $0.name < $1.name }
    }

    var albums: [Album] {
        return Dictionary(
            grouping: songs,
            by: { "\($0.artist)|\($0.albumTitle)" }
        )
        .map {
            Album(
                title: $0.value.first?.albumTitle ?? "",
                artist: $0.value.first?.artist ?? "",
                tracks: $0.value
            )
        }
        .sorted {
            $0.title < $1.title
        }
    }

    var genres: [Genre] {
        return Dictionary(grouping: songs, by: { $0.genre })
            .map { Genre(name: $0.key, tracks: $0.value) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - FUNCTIONS

    func loadSongs() {
        musicService.requestAuthorization { [weak self] authorized in
            guard let self else { return }

            guard authorized else {
                self.permissionDenied = true  // ← tell the UI
                return
            }

            Task.detached(priority: .userInitiated) {
                let fetchedSongs = self.musicService.fetchAllSongs()
                await MainActor.run {
                    self.songs = fetchedSongs
                    self.hasLoaded = true
                }
            }
        }
    }

    func addToRecentlyPlayed(id: UInt64) {
        libraryStore.addToRecentlyPlayed(id: id)
    }
}
