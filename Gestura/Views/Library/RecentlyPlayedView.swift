//
//  RecentlyPlayedView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI
internal import MusicKit

struct RecentlyPlayedView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject private var libraryStore = LibraryStore.shared
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - VIEW

    var body: some View {
        Group {
            if musicLibrary.recentlyPlayedSongs.isEmpty {
                ContentUnavailableView(
                    "Nothing Played Yet",
                    systemImage: "clock",
                    description: Text(
                        "Songs you play will appear here."
                    )
                )
            } else {
                List {
                    ForEach(musicLibrary.recentlyPlayedSongs) { song in
                        Button {
                            viewModel.play(
                                song,
                                in: musicLibrary.recentlyPlayedSongs
                            )
                        } label: {
                            SongRowView(song: song, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Recently Played")
        .toolbar {
            PlayShuffleToolbarButtons(
                songs: musicLibrary.recentlyPlayedSongs,
                viewModel: viewModel
            )
        }
    }
}
