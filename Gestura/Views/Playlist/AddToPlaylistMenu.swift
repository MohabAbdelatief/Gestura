//
//  AddToPlaylistMenu.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 13/05/2026.
//

import SwiftData
import SwiftUI
internal import MusicKit

struct AddToPlaylistMenu: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedbackCenter: FeedbackCenter
    @Query private var playlists: [Playlist]

    // MARK: - PROPERTIES

    let song: Song
    let onCreatePlaylist: () -> Void

    // MARK: - VIEW

    var body: some View {
        Menu {
            Button {
                onCreatePlaylist()
            } label: {
                Label("Create New Playlist", systemImage: "plus")
            }

            Divider()

            if playlists.isEmpty {
                Label("No Playlists", systemImage: "music.note.list")
            } else {
                ForEach(playlists) { playlist in
                    playlistButton(for: playlist)
                }
            }
        } label: {
            Label("Add to Playlist", systemImage: "text.badge.plus")
        }
    }

    // MARK: - HELPER VIEWS

    private func playlistButton(for playlist: Playlist) -> some View {
        let containsSong = playlist.songIDs.contains(song.id.rawValue)
        return Button {
            let store = PlaylistStore(context: modelContext)
            store.addSong(id: song.id, to: playlist)
            feedbackCenter.show("Added to \(playlist.name)")

        } label: {
            Label(
                playlist.name,
                systemImage: containsSong ? "checkmark" : "music.note.list"
            )
        }
        .disabled(containsSong)

    }
}
