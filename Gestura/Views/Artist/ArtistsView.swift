//
//  ArtistsView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

import SwiftUI

struct ArtistsView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var searchText = ""

    // MARK: - COMPUTED PROPERTIES

    var filteredArtists: [Artist] {
        guard !searchText.isEmpty else { return musicLibrary.artists }
        return musicLibrary.artists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - VIEW

    var body: some View {
        Group {
            if musicLibrary.artists.isEmpty {
                ContentUnavailableView(
                    "No Artists",
                    systemImage: "music.mic",
                    description: Text(
                        "No artists found."
                    )
                )
            } else if filteredArtists.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredArtists) { artist in
                        NavigationLink(
                            destination: ArtistDetailView(
                                artist: artist,
                                viewModel: viewModel
                            )
                        ) {
                            ArtistRowView(artist: artist)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }

        }
        .searchable(text: $searchText)
        .navigationTitle("Artists")
    }
}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)

    ArtistsView(viewModel: viewModel, musicLibrary: musicLibrary)
}
