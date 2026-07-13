//
//  GenreView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 08/05/2026.
//

import SwiftUI

struct GenreView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var searchText = ""

    // MARK: - COMPUTED PROPERTIES

    var filteredGenres: [Genre] {
        guard !searchText.isEmpty else { return musicLibrary.genres }
        return musicLibrary.genres.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - VIEW

    var body: some View {
        Group {
            if musicLibrary.genres.isEmpty {
                ContentUnavailableView(
                    "No Genres",
                    systemImage: "guitars",
                    description: Text(
                        "No genres found."
                    )
                )
            } else if filteredGenres.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredGenres) { genre in
                        NavigationLink(
                            destination: GenreDetailView(
                                genre: genre,
                                viewModel: viewModel
                            )
                        ) {
                            GenreRowView(genre: genre)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }

        }
        .searchable(text: $searchText)
        .navigationTitle("Genres")
    }
}
