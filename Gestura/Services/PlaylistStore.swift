//
//  PlaylistStore.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 12/05/2026.
//

import Foundation
import SwiftData
import SwiftUI
internal import MusicKit

@MainActor
final class PlaylistStore {
    // MARK: - PROPERTIES

    private let context: ModelContext

    // MARK: - INIT

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - DATA HANDLING

    func setSongIDs(_ ids: [MusicItemID], for playlist: Playlist) {
        playlist.songIDs = ids.map(\.rawValue)
        tryToSave()
    }

    func createPlaylist(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        context.insert(playlist)
        tryToSave()
        return playlist
    }

    func renamePlaylist(_ playlist: Playlist, newName: String) {
        playlist.name = newName
        tryToSave()
    }

    func deletePlaylist(_ playlist: Playlist) {
        context.delete(playlist)
        tryToSave()
    }

    func addSong(id: MusicItemID, to playlist: Playlist) {
        guard !playlist.songIDs.contains(id.rawValue) else { return }
        playlist.songIDs.append(id.rawValue)
        tryToSave()
    }

    func removeSong(id: MusicItemID, from playlist: Playlist) {
        playlist.songIDs.removeAll(where: { $0 == id.rawValue })
        tryToSave()
    }

    func moveSong(
        in playlist: Playlist,
        from source: IndexSet,
        to destination: Int
    ) {
        playlist.songIDs.move(fromOffsets: source, toOffset: destination)
        tryToSave()
    }

    // MARK: - HELPERS

    private func tryToSave() {
        do {
            try context.save()
        } catch {
            log("Save failed: \(error)")
        }
    }
}
