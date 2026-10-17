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
    private var cancellables = Set<AnyCancellable>()

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
    @Published private(set) var subscription: MusicSubscription?

    private(set) var songsByID: [MusicItemID: Song] = [:]
    @Published private(set) var catalogSongsByID: [MusicItemID: Song] = [:]

    // MARK: - INIT

    init() {
        libraryStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                Task { await self?.loadSavedCatalogSongs() }
            }
            .store(in: &cancellables)
    }

    // MARK: - COMPUTED PROPERTIES

    var recentlyPlayedSongs: [Song] {
        libraryStore.recentlyPlayedIDs.compactMap { id in
            song(for: id)
        }
    }

    var favoriteSongs: [Song] {
        libraryStore.favoriteIDs.compactMap { id in
            song(for: id)
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
            await loadSavedCatalogSongs()
        }
    }

    /// Library songs first, then songs fetched from Apple Music.
    func song(for id: MusicItemID) -> Song? {
        songsByID[id] ?? catalogSongsByID[id]
    }

    /// Fetches the Apple Music songs among `ids` that aren't loaded yet.
    func loadCatalogSongs(ids: [MusicItemID]) async {
        guard hasLoaded else { return }
        let missingIDs = ids.filter { song(for: $0) == nil }
        guard !missingIDs.isEmpty else { return }
        do {
            let fetched = try await musicService.fetchCatalogSongs(ids: missingIDs)
            for song in fetched {
                catalogSongsByID[song.id] = song
            }
        } catch {
            log("Fetching saved Apple Music songs failed: \(error)")
        }
    }

    private func loadSavedCatalogSongs() async {
        let ids = libraryStore.favoriteIDs + libraryStore.recentlyPlayedIDs
        await loadCatalogSongs(ids: ids)
    }

    func songs(in album: Album) -> [Song] {
        songs.filter {
            $0.albumTitle == album.title && $0.artistName == album.artistName
        }
    }

    func songs(by artist: Artist) -> [Song] {
        songs.filter { $0.artistName == artist.name }
    }

    func songs(in genre: Genre) async -> [Song] {
        do {
            return try await musicService.fetchSongs(in: genre)
        } catch {
            log("Fetching genre songs failed: \(error)")
            return []
        }
    }

    func catalogSongs(in album: Album) async -> [Song] {
        do {
            return try await musicService.fetchCatalogSongs(in: album)
        } catch {
            log("Fetching album songs failed: \(error)")
            return []
        }
    }

    func catalogSongs(by artist: Artist) async -> [Song] {
        do {
            return try await musicService.fetchCatalogSongs(by: artist)
        } catch {
            log("Fetching artist songs failed: \(error)")
            return []
        }
    }

    func searchCatalog(for term: String) async -> MusicCatalogSearchResponse? {
        do {
            return try await musicService.searchCatalog(for: term)
        } catch {
            log("Apple Music search failed: \(error)")
            return nil
        }
    }

    func observeSubscription() async {
        subscription = try? await MusicSubscription.current
        for await update in MusicSubscription.subscriptionUpdates {
            subscription = update
        }
    }

    func addToRecentlyPlayed(id: MusicItemID) {
        libraryStore.addToRecentlyPlayed(id: id)
    }
}
