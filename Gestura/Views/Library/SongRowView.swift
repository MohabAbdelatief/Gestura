//
//  SongRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

internal import MediaPlayer
import SwiftData
import SwiftUI

struct SongRowView: View {
    // MARK: - PROPERTIES

    let track: Track

    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject private var libraryStore = LibraryStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedbackCenter: FeedbackCenter

    // MARK: - STATE

    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""

    @EnvironmentObject private var dispatcher: PlaybackIntentDispatcher

    // MARK: - VIEW

    var body: some View {
        HStack(spacing: 12) {
            artworkThumbnail
            trackInfo
            Spacer()
            favoriteButton
            durationLabel
        }

        .contentShape(Rectangle())
        .contextMenu {
            AddToPlaylistMenu(
                track: track,
                onCreatePlaylist: {
                    showNewPlaylistAlert = true
                }
            )
            addToFavoritesMenu

        }
        .alert("New Playlist", isPresented: $showNewPlaylistAlert) {
            TextField("Playlist Name", text: $newPlaylistName)

            Button("Create") {
                createPlaylistAndAddTrack()
            }

            Button("Cancel", role: .cancel) {
                newPlaylistName = ""
            }
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkThumbnail: some View {
        Group {
            if let image = track.artwork?.image(
                at: CGSize(width: 44, height: 44)
            ) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
            }
        }
    }

    private var trackInfo: some View {
        let isActive = viewModel.currentTrack?.id == track.id
        return VStack(alignment: .leading) {
            Text(track.title)
                .font(.subheadline)
                .lineLimit(1)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundStyle(isActive ? .blue : .primary)
            Text(track.artist)
                .font(.caption)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    private var favoriteButton: some View {
        Group {
            if libraryStore.isFavorite(id: track.id) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.blue)
            }
        }
    }

    private var durationLabel: some View {
        Text(formatTime(track.duration))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - HELPERS

    private func createPlaylistAndAddTrack() {
        let trimmedName = newPlaylistName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        let store = PlaylistStore(context: modelContext)
        let playlist = store.createPlaylist(name: trimmedName)
        store.addTrack(trackID: track.id, to: playlist)

        newPlaylistName = ""
        feedbackCenter.show("Added to \(playlist.name)")
    }

    private var addToFavoritesMenu: some View {
        Button {
            let isCurrentlyFavorited = libraryStore.isFavorite(id: track.id)
            dispatcher.execute(
                .setFavorite(
                    id: track.id,
                    isFavorited: !isCurrentlyFavorited
                )
            )
        } label: {
            let isFavorited = libraryStore.isFavorite(id: track.id)
            Label(
                isFavorited ? "Remove from Favorites" : "Add to Favorites",
                systemImage: isFavorited ? "star.slash" : "star"
            )
        }
    }
}
