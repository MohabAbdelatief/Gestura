//
//  SongListView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 20/04/2026.
//

internal import MediaPlayer
import SwiftUI

struct SongListView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary
    @AppStorage("songSortingOption") private var songSortingOption: SortOption =
        .title

    // MARK: - COMPUTED PROPERTIES

    var sortedSongs: [Track] {
        switch songSortingOption {
        case .title:
            return musicLibrary.songs.sorted { $0.title < $1.title }
        case .artist:
            return musicLibrary.songs.sorted { $0.artist < $1.artist }
        case .album:
            return musicLibrary.songs.sorted { $0.albumTitle < $1.albumTitle }
        case .dateAdded:
            return musicLibrary.songs.sorted { $1.dateAdded < $0.dateAdded }
        }

    }

    // MARK: - VIEW

    var body: some View {
        List {
            ForEach(sortedSongs) { song in
                Button {
                    viewModel.play(song, in: sortedSongs)
                } label: {
                    SongRowView(track: song, viewModel: viewModel)
                }
                .buttonStyle(.plain)

            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Songs")
        .toolbar {
            PlayShuffleToolbarButtons(tracks: sortedSongs, viewModel: viewModel)
            SortOptionMenu(selection: $songSortingOption)
        }

    }
}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)

    SongListView(viewModel: viewModel, musicLibrary: musicLibrary)
}
