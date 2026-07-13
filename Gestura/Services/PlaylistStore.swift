//
//  PlaylistStore.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 12/05/2026.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PlaylistStore {
    // MARK: - PROPERTIES

    private let context: ModelContext

    // MARK: - INIT

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - DATA HANDLING

    func setTrackIDs(_ ids: [UInt64], for playlist: Playlist) {
        playlist.trackIDs = ids
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

    func addTrack(trackID: UInt64, to playlist: Playlist) {
        guard !playlist.trackIDs.contains(trackID) else { return }
        playlist.trackIDs.append(trackID)
        tryToSave()
    }

    func removeTrack(trackID: UInt64, from playlist: Playlist) {
        playlist.trackIDs.removeAll(where: { $0 == trackID })
        tryToSave()
    }

    func moveTrack(
        in playlist: Playlist,
        from source: IndexSet,
        to destination: Int
    ) {
        playlist.trackIDs.move(fromOffsets: source, toOffset: destination)
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
