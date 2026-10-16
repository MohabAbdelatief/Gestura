//
//  MusicLibraryViewModel.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 15/05/2026.
//

import Combine
import Foundation
internal import MusicKit

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
    @Published private(set) var songs: [Song] = [] {
        didSet {
            songsByID = Dictionary(
                songs.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }

    @Published private(set) var artists: [Artist] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var genres: [Genre] = []

    private(set) var songsByID: [MusicItemID: Song] = [:]

    // MARK: - COMPUTED PROPERTIES

    var recentlyPlayedSongs: [Song] {
        libraryStore.recentlyPlayedIDs.compactMap { id in
            songsByID[id]
        }
    }

    var favoriteSongs: [Song] {
        libraryStore.favoriteIDs.compactMap { id in
            songsByID[id]
        }
    }

    // MARK: - FUNCTIONS

    func requestAccess() async {
        guard await musicService.requestAuthorization() else {
            permissionDenied = true  // ← tell the UI
            return
        }
        fetchLibrary()
    }

    func loadSongs() {
        Task { await requestAccess() }
    }

    private func fetchLibrary() {
        Task {
            do {
                songs = try await musicService.fetchAll(Song.self)
                artists = try await musicService.fetchAll(Artist.self)
                    .sorted { $0.name < $1.name }
                albums = try await musicService.fetchAll(Album.self)
                    .sorted { $0.title < $1.title }
                genres = try await musicService.fetchAll(Genre.self)
                    .sorted { $0.name < $1.name }
            } catch {
                log("Fetching songs failed: \(error)")
            }
            hasLoaded = true
        }
    }

    func songs(in album: Album) -> [Song] {
        songs.filter {
            $0.albumTitle == album.title && $0.artistName == album.artistName
        }
    }

    func songs(by artist: Artist) -> [Song] {
        songs.filter { $0.artistName == artist.name }
    }

    func songs(in genre: Genre) -> [Song] {
        songs.filter { $0.genreNames.contains(genre.name) }
    }

    func addToRecentlyPlayed(id: MusicItemID) {
        libraryStore.addToRecentlyPlayed(id: id)
    }
}
