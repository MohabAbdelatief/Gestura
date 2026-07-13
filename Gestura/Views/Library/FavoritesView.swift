//
//  FavoritesView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct FavoritesView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject private var libraryStore = LibraryStore.shared
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE
    @AppStorage("favoritesSortingOption") private var favoritesSortingOption:
        SortOption = .title
    @State private var searchText = ""

    // MARK: - COMPUTED PROPERTIES

    var filteredSongs: [Track] {
        guard !searchText.isEmpty else { return musicLibrary.favoriteTracks }
        return musicLibrary.favoriteTracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
                || $0.albumTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var sortedFavorites: [Track] {
        switch favoritesSortingOption {
        case .title:
            return filteredSongs.sorted { $0.title < $1.title }
        case .artist:
            return filteredSongs.sorted { $0.artist < $1.artist }
        case .album:
            return filteredSongs.sorted { $0.albumTitle < $1.albumTitle }
        case .dateAdded:
            return filteredSongs.sorted { $1.dateAdded < $0.dateAdded }
        }

    }

    // MARK: - HELPER VIEWS

    private var artworkHeader: some View {
        Group {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(radius: 6)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(
                    Image(systemName: "star.fill")
                        .font(.system(size: 140))
                        .foregroundStyle(.blue)
                )
        }
    }

    // MARK: - VIEW

    var body: some View {
        Group {
            if musicLibrary.favoriteTracks.isEmpty {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "star",
                    description: Text(
                        "Tap the star on any song to add it here."
                    )
                )
            } else if sortedFavorites.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    artworkHeader
                    ForEach(sortedFavorites) { track in
                        Button {
                            viewModel.play(track, in: sortedFavorites)
                        } label: {
                            SongRowView(track: track, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Favorites")
        .searchable(text: $searchText)
        .toolbar {
            PlayShuffleToolbarButtons(
                tracks: sortedFavorites,
                viewModel: viewModel
            )
            SortOptionMenu(selection: $favoritesSortingOption)
        }
    }

}
