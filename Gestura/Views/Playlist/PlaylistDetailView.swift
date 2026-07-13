//
//  PlaylistDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 13/05/2026.
//

import SwiftData
import SwiftUI

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

    private var tracks: [Track] {
        playlist.trackIDs.compactMap { id in
            musicLibrary.tracksByID[id]
        }
    }

    // MARK: - VIEW

    var body: some View {
        Group {
            if tracks.isEmpty {
                ContentUnavailableView(
                    "Empty Playlist",
                    systemImage: "music.note.list",
                    description: Text("Add songs from your library.")
                )
            } else {
                tracksList
            }
        }
        .navigationTitle(playlist.name)
        .toolbar {
            if !tracks.isEmpty {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        viewModel.setShuffleEnabled(false)
                        if let firstTrack = tracks.first {
                            viewModel.play(firstTrack, in: tracks)
                        }
                    } label: {
                        Label("Play All", systemImage: "play.fill")
                    }

                    Button {
                        viewModel.setShuffleEnabled(true)
                        if let randomTrack = tracks.randomElement() {
                            viewModel.play(randomTrack, in: tracks)
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
    private var tracksList: some View {
        List {
            artworkHeader
            ForEach(tracks) { track in
                trackRow(for: track)
            }
            .onDelete { offsets in
                let store = PlaylistStore(context: modelContext)
                let idsToDelete = offsets.map { tracks[$0].id }
                for id in idsToDelete {
                    store.removeTrack(trackID: id, from: playlist)
                }
            }
            .onMove { source, destination in
                let newOrder = reorderedTrackIDs(
                    source: source,
                    destination: destination
                )
                let store = PlaylistStore(context: modelContext)
                store.setTrackIDs(newOrder, for: playlist)
            }
        }
    }

    private func trackRow(for track: Track) -> some View {
        Button {
            viewModel.play(track, in: tracks)
        } label: {
            SongRowView(track: track, viewModel: viewModel)
        }
        .buttonStyle(.plain)
    }

    // MARK: - HELPERS

    private func reorderedTrackIDs(source: IndexSet, destination: Int)
        -> [UInt64]
    {
        var reorderedTracks = tracks
        reorderedTracks.move(fromOffsets: source, toOffset: destination)
        let newResolvedIDs = reorderedTracks.map { $0.id }

        let resolvedSet = Set(tracks.map { $0.id })
        var queue = newResolvedIDs

        return playlist.trackIDs.map { id in
            if resolvedSet.contains(id) {
                return queue.removeFirst()
            } else {
                return id
            }
        }
    }
}
