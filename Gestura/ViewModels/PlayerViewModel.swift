//
//  PlayerViewModel.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//

import Combine
import Foundation
internal import MusicKit
import SwiftUI

@MainActor
class PlayerViewModel: ObservableObject {
    // MARK: - PROPERTIES

    private var timerTask: Task<Void, Never>?
    private let musicService = MusicService.shared
    private var originalQueue: [Song] = []
    private let musicLibrary: MusicLibrary

    let volumeManager = VolumeManager()

    // MARK: - PUBLISHED PROPERTIES

    @Published var playerState: PlayerState = .idle
    @Published var repeatMode: RepeatMode
    @Published var currentTime: TimeInterval = 0
    @Published var isScrubbing: Bool = false
    @Published var scrubTime: TimeInterval = 0
    @Published var queue: [Song] = []
    @Published var queueIndex: Int = 0
    @Published var isShuffleEnabled: Bool = false

    // MARK: - COMPUTED PROPERTIES

    var currentSong: Song? {
        switch playerState {
        case .idle:
            return nil
        case .playing(let song):
            return song
        case .paused(let song):
            return song
        }
    }

    var isPlaying: Bool {
        if case .playing = playerState {
            return true
        }
        return false
    }

    var currentQueueSong: Song? {
        guard queue.indices.contains(queueIndex) else { return nil }
        return queue[queueIndex]
    }

    // MARK: - INIT

    init(musicLibrary: MusicLibrary) {
        self.musicLibrary = musicLibrary
        let stored: String? = UserDefaults.standard.string(
            forKey: "defaultRepeatMode"
        )
        let mode: RepeatMode? = stored.flatMap(RepeatMode.init(rawValue:))
        let final: RepeatMode = mode ?? .off
        repeatMode = final
        musicService.setRepeatMode(repeatMode)

        isShuffleEnabled = UserDefaults.standard.bool(forKey: "shuffleEnabled")
        musicService.setShuffleMode(false)
    }

    // MARK: - FUNCTIONS

    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "defaultRepeatMode")
        musicService.setRepeatMode(mode)
    }

    // MARK: - OBSERVERS

    func observePlayer() {
        Task {
            for await _ in Observations({ self.musicService.currentEntryIndex }) {
                updateNowPlaying()
            }
        }
        Task {
            for await _ in Observations({ self.musicService.playbackStatus }) {
                reconcilePlaybackState()
            }
        }
    }

    private func reconcilePlaybackState() {
        guard let song = currentSong else { return }

        switch musicService.playbackStatus {
        case .playing:
            if !isPlaying {
                playerState = .playing(song)
                startTimer()
            }
        case .paused, .stopped, .interrupted:
            if isPlaying {
                playerState = .paused(song)
                stopTimer()
            }
        case .seekingForward, .seekingBackward:
            break
        @unknown default:
            break
        }
    }

    // MARK: - PLAYBACK

    func play(_ song: Song, in context: [Song]) {
        originalQueue = context

        if isShuffleEnabled {
            var rest = context.filter { $0.id != song.id }
            rest.shuffle()
            queue = [song] + rest
            queueIndex = 0
        } else {
            queue = context
            queueIndex = context.firstIndex(where: { $0.id == song.id }) ?? 0
        }

        playCurrentQueueSong()
    }
    
    enum StartPlaybackResult {
        case started(Song)
        case libraryLoading
        case libraryEmpty
        case accessDenied
    }

    enum PendingStart {
        case resume(Song)
        case shuffleLibrary
        case libraryLoading
        case libraryEmpty
        case accessDenied
    }

    var pendingStart: PendingStart {
        if musicLibrary.permissionDenied { return .accessDenied }
        guard musicLibrary.hasLoaded else { return .libraryLoading }

        if let recent = musicLibrary.recentlyPlayedSongs.first {
            return .resume(recent)
        }
        return musicLibrary.songs.isEmpty ? .libraryEmpty : .shuffleLibrary
    }

    @discardableResult
    func startPlayback() -> StartPlaybackResult {
        if let current = currentSong { return .started(current) }

        switch pendingStart {
        case .accessDenied:
            return .accessDenied
        case .libraryLoading:
            return .libraryLoading
        case .libraryEmpty:
            return .libraryEmpty
        case .resume(let song):
            play(song, in: musicLibrary.recentlyPlayedSongs)
            return .started(song)
        case .shuffleLibrary:
            guard let song = musicLibrary.songs.randomElement() else {
                return .libraryEmpty
            }
            play(song, in: musicLibrary.songs)
            return .started(song)
        }
    }

    func nextTrack() {
        musicService.nextTrack()
    }

    func previousTrack() {
        musicService.previousTrack()
    }

    // MARK: - CONTROLS

    func cycleRepeatMode() {
        let all = RepeatMode.allCases
        let currentIndex = all.firstIndex(of: repeatMode) ?? 0
        let nextIndex = (currentIndex + 1) % all.count
        setRepeatMode(all[nextIndex])
    }

    @discardableResult
    func togglePlayPause() -> Bool? {
        switch playerState {
        case .idle:
            return nil
        case .playing(let song):
            musicService.pause()
            playerState = .paused(song)
            stopTimer()
            return false
        case .paused(let song):
            musicService.resume()
            playerState = .playing(song)
            startTimer()
            return true
        }
    }

    func toggleShuffle() {
        isShuffleEnabled.toggle()
        UserDefaults.standard.set(isShuffleEnabled, forKey: "shuffleEnabled")

        guard !queue.isEmpty else { return }
        let current = queue[queueIndex]

        if isShuffleEnabled {
            var rest = queue.filter { $0.id != current.id }
            rest.shuffle()
            queue = [current] + rest
            queueIndex = 0
        } else {
            queue = originalQueue
            queueIndex = queue.firstIndex(where: { $0.id == current.id }) ?? 0
        }

        musicService.play(queue, startingAt: queueIndex)
    }

    func setShuffleEnabled(_ enabled: Bool) {
        guard isShuffleEnabled != enabled else { return }

        isShuffleEnabled = enabled
        UserDefaults.standard.set(isShuffleEnabled, forKey: "shuffleEnabled")
        musicService.setShuffleMode(isShuffleEnabled)
    }

    // MARK: - PROGRESS SLIDER

    func startScrubbing() {
        isScrubbing = true
        scrubTime = currentTime
    }

    func scrub(to time: TimeInterval) {
        scrubTime = time
    }

    func endScrubbing() {
        musicService.seek(to: scrubTime)
        currentTime = scrubTime
        isScrubbing = false
    }

    // MARK: - QUEUE MANAGEMENT

    func removeQueueItem(at offsets: IndexSet) {
        let currentSongID = currentQueueSong?.id

        queue.remove(atOffsets: offsets)
        musicService.removeFromQueue(atOffsets: offsets)

        if queue.isEmpty {
            playerState = .idle
            return
        }

        if let id = currentSongID,
            let newIndex = queue.firstIndex(where: { $0.id == id })
        {
            queueIndex = newIndex
        } else {
            queueIndex = min(queueIndex, queue.count - 1)
        }
    }

    func moveQueueItems(from source: IndexSet, to destination: Int) {
        let currentSongID = currentQueueSong?.id

        queue.move(fromOffsets: source, toOffset: destination)
        musicService.moveInQueue(fromOffsets: source, toOffset: destination)

        if let id = currentSongID,
            let newIndex = queue.firstIndex(where: { $0.id == id })
        {
            queueIndex = newIndex
        }
    }

    private func updateNowPlaying() {
        if let index = musicService.currentEntryIndex,
            queue.indices.contains(index)
        {
            queueIndex = index
            let song = queue[index]
            musicLibrary.addToRecentlyPlayed(id: song.id)

            switch musicService.playbackStatus {
            case .playing:
                playerState = .playing(song)
                startTimer()
            case .paused, .stopped, .interrupted:
                playerState = .paused(song)
                stopTimer()
            case .seekingForward, .seekingBackward:
                break
            @unknown default:
                break
            }
        }
    }

    private func playCurrentQueueSong() {
        guard queue.indices.contains(queueIndex) else { return }
        let song = queue[queueIndex]
        musicService.play(queue, startingAt: queueIndex)
        playerState = .playing(song)
        startTimer()
    }

    func jumpTo(_ index: Int) {
        queueIndex = index
        playCurrentQueueSong()
    }

    // MARK: - HELPERS

    private func startTimer() {
        stopTimer()

        timerTask = Task {
            while !Task.isCancelled {
                if !isScrubbing {
                    currentTime = musicService.currentPlaybackTime
                }
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

}
