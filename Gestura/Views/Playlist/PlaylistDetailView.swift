//
//  PlaylistDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 13/05/2026.
//

import SwiftData
import SwiftUI
internal import MusicKit

struct PlaylistDetailView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary
    @Environment(\.modelContext) private var modelContext

    // MARK: - PROPERTIES

    let playlist: Playlist

    // MARK: - COMPUTED PROPERTIES
    
    private var artworkHeader: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white)
            .shadow(radius: 6)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: 140))
                    .foregroundStyle(.blue)
            )
    }

    private var songs: [Song] {
        playlist.songIDs.compactMap { id in
            musicLibrary.song(for: MusicItemID(id))
        }
    }

    // MARK: - VIEW

    var body: some View {
        Group {
            if songs.isEmpty {
                ContentUnavailableView(
                    "Empty Playlist",
                    systemImage: "music.note.list",
                    description: Text("Add songs from your library.")
                )
            } else {
                songsList
            }
        }
        .navigationTitle(playlist.name)
        .task(id: playlist.songIDs) {
            await musicLibrary.loadCatalogSongs(
                ids: playlist.songIDs.map { MusicItemID($0) }
            )
        }
        .toolbar {
            if !songs.isEmpty {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        viewModel.setShuffleEnabled(false)
                        if let firstSong = songs.first {
                            viewModel.play(firstSong, in: songs)
                        }
                    } label: {
                        Label("Play All", systemImage: "play.fill")
                    }

                    Button {
                        viewModel.setShuffleEnabled(true)
                        if let randomSong = songs.randomElement() {
                            viewModel.play(randomSong, in: songs)
                        }
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }

                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }

        }
    }

    // MARK: - HELPER VIEWS
    private var songsList: some View {
        List {
            artworkHeader
            ForEach(songs) { song in
                songRow(for: song)
            }
            .onDelete { offsets in
                let store = PlaylistStore(context: modelContext)
                let idsToDelete = offsets.map { songs[$0].id }
                for id in idsToDelete {
                    store.removeSong(id: id, from: playlist)
                }
            }
            .onMove { source, destination in
                let newOrder = reorderedSongIDs(
                    source: source,
                    destination: destination
                )
                let store = PlaylistStore(context: modelContext)
                store.setSongIDs(newOrder, for: playlist)
            }
        }
    }

    private func songRow(for song: Song) -> some View {
        Button {
            viewModel.play(song, in: songs)
        } label: {
            SongRowView(song: song, viewModel: viewModel)
        }
        .buttonStyle(.plain)
    }

    // MARK: - HELPERS

    private func reorderedSongIDs(source: IndexSet, destination: Int)
        -> [MusicItemID]
    {
        var reorderedSongs = songs
        reorderedSongs.move(fromOffsets: source, toOffset: destination)
        let newResolvedIDs = reorderedSongs.map { $0.id }

        let resolvedSet = Set(songs.map { $0.id })
        var queue = newResolvedIDs

        return playlist.songIDs.map { rawID in
            let id = MusicItemID(rawID)
            if resolvedSet.contains(id) {
                return queue.removeFirst()
            } else {
                return id
            }
        }
    }
}
