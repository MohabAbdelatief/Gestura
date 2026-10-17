//
//  SearchTabView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI
internal import MusicKit

struct SearchTabView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var searchText: String = ""
    @State private var scope: SearchScope = .library
    @State private var catalogResults: MusicCatalogSearchResponse?
    @State private var isLoadingCatalog = false
    @State private var showSubscriptionOffer = false

    enum SearchScope {
        case library
        case appleMusic
    }

    // MARK: - COMPUTED PROPERTIES

    var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return [] }
        return musicLibrary.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artistName.localizedCaseInsensitiveContains(searchText)
                || ($0.albumTitle ?? "").localizedCaseInsensitiveContains(
                    searchText
                )
        }
    }

    var filteredArtists: [Artist] {
        guard !searchText.isEmpty else { return [] }
        return musicLibrary.artists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return [] }
        return musicLibrary.albums.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artistName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var isCatalog: Bool {
        scope == .appleMusic
    }

    private var songs: [Song] {
        isCatalog ? Array(catalogResults?.songs ?? []) : filteredSongs
    }

    private var artists: [Artist] {
        isCatalog ? Array(catalogResults?.artists ?? []) : filteredArtists
    }

    private var albums: [Album] {
        isCatalog ? Array(catalogResults?.albums ?? []) : filteredAlbums
    }

    private var canPlay: Bool {
        !isCatalog || musicLibrary.subscription?.canPlayCatalogContent == true
    }

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        isCatalog ? "Search Apple Music" : "Search Your Library",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Find songs by title, artist, or album."
                        )
                    )
                } else if isCatalog && isLoadingCatalog {
                    ProgressView("Searching…")
                } else if songs.isEmpty && albums.isEmpty && artists.isEmpty {
                    ContentUnavailableView.search(text: searchText)

                } else {
                    List {
                        if !songs.isEmpty {
                            Section("Songs") {
                                ForEach(songs) { song in
                                    Button {
                                        play(song)
                                    } label: {
                                        SongRowView(
                                            song: song,
                                            viewModel: viewModel
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if !artists.isEmpty {
                            Section("Artists") {
                                ForEach(artists) { artist in
                                    NavigationLink(
                                        destination: ArtistDetailView(
                                            artist: artist,
                                            isCatalog: isCatalog,
                                            viewModel: viewModel,
                                            musicLibrary: musicLibrary
                                        )
                                    ) { ArtistRowView(artist: artist) }
                                }
                            }
                        }
                        if !albums.isEmpty {
                            Section("Albums") {
                                ForEach(albums) { album in
                                    NavigationLink(
                                        destination: AlbumDetailView(
                                            viewModel: viewModel,
                                            musicLibrary: musicLibrary,
                                            album: album,
                                            isCatalog: isCatalog
                                        )
                                    ) {
                                        AlbumRowView(album: album)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText)
            .searchScopes($scope, activation: .onSearchPresentation) {
                Text("Library").tag(SearchScope.library)
                Text("Apple Music").tag(SearchScope.appleMusic)
            }
            .task(id: "\(scope)-\(searchText)") {
                guard isCatalog, !searchText.isEmpty else {
                    isLoadingCatalog = false
                    return
                }
                isLoadingCatalog = true
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                let results = await musicLibrary.searchCatalog(for: searchText)
                guard !Task.isCancelled else { return }
                catalogResults = results
                isLoadingCatalog = false
            }
            .musicSubscriptionOffer(
                isPresented: $showSubscriptionOffer,
                options: .gestura
            )
        }
    }

    // MARK: - HELPERS

    private func play(_ song: Song) {
        if canPlay {
            viewModel.play(song, in: songs)
        } else {
            showSubscriptionOffer = true
        }
    }

}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)

    SearchTabView(viewModel: viewModel, musicLibrary: musicLibrary)
}
