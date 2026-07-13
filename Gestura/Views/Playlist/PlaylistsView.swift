//
//  PlaylistView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 13/05/2026.
//

import SwiftData
import SwiftUI

struct PlaylistsView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    // MARK: - STATE

    @State private var selectedPlaylist: Playlist?
    @State private var showNewPlaylistAlert = false
    @State private var showRenamePlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var playlistToRename: Playlist?
    @State private var renamePlaylistName = ""
    @State private var showDeletePlaylistConfirmation = false
    @State private var playlistsPendingDeletion: [Playlist] = []

    // MARK: - QUERY

    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists:
        [Playlist]

    // MARK: - ENVIRONMENT

    @Environment(\.modelContext) private var modelContext

    // MARK: - OBSERVED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - VIEW

    var body: some View {
        Group {
            if playlists.isEmpty {
                emptyState
            } else {
                playlistList
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Playlists")
        .navigationDestination(item: $selectedPlaylist) { playlist in
            PlaylistDetailView(
                viewModel: viewModel,
                musicLibrary: musicLibrary,
                playlist: playlist
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewPlaylistAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Playlist", isPresented: $showNewPlaylistAlert) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Create") {
                let trimmedName = newPlaylistName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard !trimmedName.isEmpty else { return }

                let store = PlaylistStore(context: modelContext)
                let newPlaylist = store.createPlaylist(name: trimmedName)
                newPlaylistName = ""
                selectedPlaylist = newPlaylist
            }
            Button("Cancel", role: .cancel) {
                newPlaylistName = ""
            }
        }
        .alert("Rename Playlist", isPresented: $showRenamePlaylistAlert) {
            TextField("Playlist Name", text: $renamePlaylistName)
            Button("Save") {
                let trimmedName = renamePlaylistName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard !trimmedName.isEmpty else { return }
                guard let playlist = playlistToRename else { return }

                let store = PlaylistStore(context: modelContext)
                store.renamePlaylist(playlist, newName: trimmedName)

                playlistToRename = nil
                renamePlaylistName = ""
            }
            Button("Cancel", role: .cancel) {
                playlistToRename = nil
                renamePlaylistName = ""
            }
        }
        .alert("Delete Playlist?", isPresented: $showDeletePlaylistConfirmation)
        {
            Button("Delete", role: .destructive) {
                let store = PlaylistStore(context: modelContext)
                playlistsPendingDeletion.forEach { playlist in
                    store.deletePlaylist(playlist)
                }
                playlistsPendingDeletion = []
            }
            Button("Cancel", role: .cancel) {
                playlistsPendingDeletion = []
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - HELPER VIEWS

    private var emptyState: some View {
        ContentUnavailableView(
            "No Playlists",
            systemImage: "list.bullet.rectangle",
            description: Text(
                "Create a new playlist by tapping the plus button in the navigation bar."
            )
        )
    }

    private var playlistList: some View {
        List {
            ForEach(playlists) { playlist in
                playlistRow(for: playlist)
            }
            .onDelete { offsets in
                playlistsPendingDeletion = offsets.map { playlists[$0] }
                showDeletePlaylistConfirmation = true
            }
        }
    }

    private func playlistRow(for playlist: Playlist) -> some View {
        NavigationLink {
            PlaylistDetailView(
                viewModel: viewModel,
                musicLibrary: musicLibrary,
                playlist: playlist
            )
        } label: {
            PlaylistRowView(playlist: playlist)
        }
        .contextMenu {
            Button {
                playlistToRename = playlist
                renamePlaylistName = playlist.name
                showRenamePlaylistAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
        }
    }
}
