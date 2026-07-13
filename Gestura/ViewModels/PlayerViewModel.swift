//
//  PlayerViewModel.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//

import Combine
import Foundation
internal import MediaPlayer
import SwiftUI

@MainActor
class PlayerViewModel: ObservableObject {
    // MARK: - PROPERTIES

    private var timerTask: Task<Void, Never>?
    private var pendingReconcileTask: Task<Void, Never>?
    private let musicService = MusicService.shared
    private var nowPlayingObserver: NSObjectProtocol?
    private var playbackStateObserver: NSObjectProtocol?
    private var originalQueue: [Track] = []
    private let musicLibrary: MusicLibrary

    let volumeManager = VolumeManager()

    // MARK: - PUBLISHED PROPERTIES

    @Published var playerState: PlayerState = .idle
    @Published var repeatMode: RepeatMode
    @Published var currentTime: TimeInterval = 0
    @Published var isScrubbing: Bool = false
    @Published var scrubTime: TimeInterval = 0
    @Published var queue: [Track] = []
    @Published var queueIndex: Int = 0
    @Published var isShuffleEnabled: Bool = false

    // MARK: - COMPUTED PROPERTIES

    var currentTrack: Track? {
        switch playerState {
        case .idle:
            return nil
        case .playing(let track):
            return track
        case .paused(let track):
            return track
        }
    }

    var isPlaying: Bool {
        if case .playing = playerState {
            return true
        }
        return false
    }

    var currentQueueTrack: Track? {
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

    func observeNowPlaying() {
        nowPlayingObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateNowPlaying()
            }
        }
        playbackStateObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handlePlaybackStateChange()
            }
        }
        musicService.startObserving()
    }

    private func handlePlaybackStateChange() {
        reconcilePlaybackState()
        // MPMusicPlayerController.applicationQueuePlayer posts the state-change
        // notification before its `playbackState` property finishes propagating,
        // so an immediate reconcile can read a stale value. Re-check shortly
        // after to settle the UI when the property catches up.
        pendingReconcileTask?.cancel()
        pendingReconcileTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self?.reconcilePlaybackState()
        }
    }

    private func reconcilePlaybackState() {
        guard let track = currentTrack else { return }

        switch musicService.playbackState {
        case .playing:
            if !isPlaying {
                playerState = .playing(track)
                startTimer()
            }
        case .paused, .stopped, .interrupted:
            if isPlaying {
                playerState = .paused(track)
                stopTimer()
            }
        case .seekingForward, .seekingBackward:
            break
        @unknown default:
            break
        }
    }

    deinit {
        if let observer = nowPlayingObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = playbackStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        pendingReconcileTask?.cancel()
        let service = musicService
        Task { @MainActor in
            service.stopObserving()
        }
    }

    // MARK: - PLAYBACK

    func play(_ track: Track, in context: [Track]) {
        originalQueue = context

        if isShuffleEnabled {
            var rest = context.filter { $0.id != track.id }
            rest.shuffle()
            queue = [track] + rest
            queueIndex = 0
        } else {
            queue = context
            queueIndex = context.firstIndex(where: { $0.id == track.id }) ?? 0
        }

        playCurrentQueueTrack()
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
        case .playing(let track):
            musicService.pause()
            playerState = .paused(track)
            stopTimer()
            return false
        case .paused(let track):
            musicService.resume()
            playerState = .playing(track)
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
        let currentTrackID = currentQueueTrack?.id
        let removedTracks = offsets.compactMap { index in
            queue.indices.contains(index) ? queue[index] : nil
        }

        queue.remove(atOffsets: offsets)
        musicService.removeFromSystemQueue(tracks: removedTracks)

        if queue.isEmpty {
            playerState = .idle
            return
        }

        if let id = currentTrackID,
            let newIndex = queue.firstIndex(where: { $0.id == id })
        {
            queueIndex = newIndex
        } else {
            queueIndex = min(queueIndex, queue.count - 1)
        }
    }

    func moveQueueItems(from source: IndexSet, to destination: Int) {
        let currentTrackID = currentQueueTrack?.id
        let movedTracks = source.compactMap {
            queue.indices.contains($0) ? queue[$0] : nil
        }

        queue.move(fromOffsets: source, toOffset: destination)

        for track in movedTracks {
            guard let newIndex = queue.firstIndex(where: { $0.id == track.id })
            else { continue }
            let predecessor = newIndex > 0 ? queue[newIndex - 1] : nil
            musicService.moveInSystemQueue(track: track, after: predecessor)
        }

        if let id = currentTrackID,
            let newIndex = queue.firstIndex(where: { $0.id == id })
        {
            queueIndex = newIndex
        }
    }

    private func updateNowPlaying() {
        guard let nowPlaying = musicService.nowPlayingItem else {
            return
        }
        if let index = queue.firstIndex(where: {
            $0.id == nowPlaying.persistentID
        }) {
            queueIndex = index
            let track = queue[index]
            musicLibrary.addToRecentlyPlayed(id: track.id)

            switch musicService.playbackState {
            case .playing:
                playerState = .playing(track)
                startTimer()
            case .paused, .stopped, .interrupted:
                playerState = .paused(track)
                stopTimer()
            case .seekingForward, .seekingBackward:
                break
            @unknown default:
                break
            }
        }
    }

    private func playCurrentQueueTrack() {
        guard queue.indices.contains(queueIndex) else { return }
        let track = queue[queueIndex]
        musicService.play(queue, startingAt: queueIndex)
        playerState = .playing(track)
        startTimer()
    }

    func jumpTo(_ index: Int) {
        queueIndex = index
        playCurrentQueueTrack()
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
