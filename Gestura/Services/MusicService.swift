//
//  MusicService.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//

import Foundation
import SwiftUI
internal import MusicKit

class MusicService {
    // MARK: - SHARED

    static let shared = MusicService()

    // MARK: - PROPERTIES

    private let player = ApplicationMusicPlayer.shared

    // MARK: - INIT

    private init() {}

    // MARK: - STATE

    var currentPlaybackTime: TimeInterval {
        player.playbackTime
    }

    var playbackStatus: MusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }

    var currentEntryIndex: Int? {
        guard let entry = player.queue.currentEntry else { return nil }
        return Array(player.queue.entries).firstIndex(of: entry)
    }

    func seek(to time: TimeInterval) {
        player.playbackTime = time
    }

    // MARK: - AUTHORIZATION

    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    // MARK: - QUEUE MANAGEMENT

    func moveInQueue(fromOffsets source: IndexSet, toOffset destination: Int) {
        player.queue.entries.move(fromOffsets: source, toOffset: destination)
    }

    func removeFromQueue(atOffsets offsets: IndexSet) {
        player.queue.entries.remove(atOffsets: offsets)
    }

    // MARK: - LIBRARY

    func fetchAll<Item: MusicLibraryRequestable>(
        _ type: Item.Type
    ) async throws -> [Item] {
        let request = MusicLibraryRequest<Item>()
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - PLAYBACK

    func play(_ songs: [Song], startingAt index: Int) {
        guard songs.indices.contains(index) else { return }
        player.queue = ApplicationMusicPlayer.Queue(
            for: songs,
            startingAt: songs[index]
        )
        resume()
    }

    func pause() {
        player.pause()
    }

    func resume() {
        Task {
            do {
                try await player.play()
            } catch {
                log("Play failed: \(error)")
            }
        }
    }

    func nextTrack() {
        Task {
            do {
                try await player.skipToNextEntry()
            } catch {
                log("Skip to next failed: \(error)")
            }
        }
    }

    func previousTrack() {
        Task {
            do {
                try await player.skipToPreviousEntry()
            } catch {
                log("Skip to previous failed: \(error)")
            }
        }
    }

    func setRepeatMode(_ mode: RepeatMode) {
        switch mode {
        case .off: player.state.repeatMode = MusicPlayer.RepeatMode.none
        case .one: player.state.repeatMode = .one
        case .all: player.state.repeatMode = .all
        }
    }

    func setShuffleMode(_ enabled: Bool) {
        player.state.shuffleMode = enabled ? .songs : .off
    }
}
