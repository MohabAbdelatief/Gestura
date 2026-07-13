//
//  AlbumView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

import SwiftUI

struct AlbumsView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var searchText = ""

    // MARK: - COMPUTED PROPERTIES

    var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return musicLibrary.albums }
        return musicLibrary.albums.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - VIEW
    var body: some View {
        Group {
            if musicLibrary.albums.isEmpty {
                ContentUnavailableView(
                    "No Albums",
                    systemImage: "square.stack",
                    description: Text(
                        "No albums found."
                    )
                )
            } else if filteredAlbums.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
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
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Albums")
    }
}
