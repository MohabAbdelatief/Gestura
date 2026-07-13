//
//  RecentlyPlayedView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct RecentlyPlayedView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject private var libraryStore = LibraryStore.shared
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - VIEW

    var body: some View {
        Group {
            if musicLibrary.recentlyPlayedTracks.isEmpty {
                ContentUnavailableView(
                    "Nothing Played Yet",
                    systemImage: "clock",
                    description: Text(
                        "Songs you play will appear here."
                    )
                )
            } else {
                List {
                    ForEach(musicLibrary.recentlyPlayedTracks) { track in
                        Button {
                            viewModel.play(
                                track,
                                in: musicLibrary.recentlyPlayedTracks
                            )
                        } label: {
                            SongRowView(track: track, viewModel: viewModel)
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
                tracks: musicLibrary.recentlyPlayedTracks,
                viewModel: viewModel
            )
        }
    }
}
