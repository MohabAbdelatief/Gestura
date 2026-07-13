//
//  SearchTabView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct SearchTabView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var searchText: String = ""

    // MARK: - COMPUTED PROPERTIES

    var filteredSongs: [Track] {
        guard !searchText.isEmpty else { return [] }
        return musicLibrary.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
                || $0.albumTitle.localizedCaseInsensitiveContains(searchText)
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
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search Your Library",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Find songs by title, artist, or album."
                        )
                    )
                } else if filteredSongs.isEmpty && filteredAlbums.isEmpty
                    && filteredArtists.isEmpty
                {
                    ContentUnavailableView.search(text: searchText)

                } else {
                    List {
                        if !filteredSongs.isEmpty {
                            Section("Songs") {
                                ForEach(filteredSongs) { song in
                                    Button {
                                        viewModel.play(
                                            song,
                                            in: filteredSongs
                                        )
                                    } label: {
                                        SongRowView(
                                            track: song,
                                            viewModel: viewModel
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if !filteredArtists.isEmpty {
                            Section("Artists") {
                                ForEach(filteredArtists) { artist in
                                    NavigationLink(
                                        destination: ArtistDetailView(
                                            artist: artist,
                                            viewModel: viewModel
                                        )
                                    ) { ArtistRowView(artist: artist) }
                                }
                            }
                        }
                        if !filteredAlbums.isEmpty {
                            Section("Albums") {
                                ForEach(filteredAlbums) { album in
                                    NavigationLink(
                                        destination: AlbumDetailView(
                                            viewModel: viewModel,
                                            album: album

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
        }
    }

}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)

    SearchTabView(viewModel: viewModel, musicLibrary: musicLibrary)
}
