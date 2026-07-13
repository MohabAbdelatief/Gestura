//
//  MusicService.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//

import Combine
import Foundation
internal import MediaPlayer

class MusicService: ObservableObject {
    // MARK: - SHARED

    static let shared = MusicService()

    // MARK: - PROPERTY WRAPPED OBJECTS

    @Published var isAuthorized = false

    // MARK: - PROPERTIES

    private let player = MPMusicPlayerController.applicationQueuePlayer

    // MARK: - INIT

    private init() {}

    // MARK: - COMPUTED PROPERTIES

    var currentPlaybackTime: TimeInterval {
        player.currentPlaybackTime
    }
    var playbackState: MPMusicPlaybackState {
        player.playbackState
    }

    var nowPlayingItem: MPMediaItem? {
        player.nowPlayingItem
    }

    // MARK: - FUNCTIONS

    func seek(to time: TimeInterval) {
        player.currentPlaybackTime = time
    }

    // MARK: - AUTHORIZATION

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                let authorized = (status == .authorized)
                self?.isAuthorized = authorized
                completion(authorized)
            }
        }
    }

    // MARK: - NOTIFICATIONS

    func startObserving() {
        player.beginGeneratingPlaybackNotifications()
    }

    func stopObserving() {
        player.endGeneratingPlaybackNotifications()
    }

    // MARK: - QUEUE MANAGEMENT

    func moveInSystemQueue(track: Track, after afterTrack: Track?) {
        player.perform(
            queueTransaction: { mutableQueue in
                guard
                    let itemToMove = mutableQueue.items.first(where: {
                        $0.persistentID == track.id
                    })
                else { return }

                mutableQueue.remove(itemToMove)

                let afterItem: MPMediaItem? = afterTrack.flatMap { t in
                    mutableQueue.items.first(where: { $0.persistentID == t.id })
                }

                let descriptor = MPMusicPlayerMediaItemQueueDescriptor(
                    itemCollection: MPMediaItemCollection(items: [itemToMove])
                )
                mutableQueue.insert(descriptor, after: afterItem)
            },
            completionHandler: { _, error in
                if let error {
                    log("Move transaction failed: \(error)")
                }
            }
        )
    }

    func removeFromSystemQueue(tracks: [Track]) {
        let trackIDs = Set(tracks.map { $0.id })
        player.perform(
            queueTransaction: { mutableQueue in
                let itemsToRemove = mutableQueue.items.filter {
                    trackIDs.contains($0.persistentID)
                }
                for item in itemsToRemove {
                    mutableQueue.remove(item)
                }
            },
            completionHandler: { _, error in
                if let error {
                    log("Queue transaction failed: \(error)")
                }
            }
        )
    }

    // MARK: - TRACKS LOGIC

    nonisolated func fetchAllSongs() -> [Track] {
        let query = MPMediaQuery.songs()
        guard let items = query.items else { return [] }
        return items.map { item in
            Track(
                id: item.persistentID,
                title: item.title ?? "Unknown Title",
                artist: item.artist ?? "Unknown Artist",
                albumTitle: item.albumTitle ?? "Unknown Album",
                duration: item.playbackDuration,
                artwork: item.artwork,
                dateAdded: item.dateAdded,
                genre: item.genre ?? "Unknown Genre",
                lyrics: item.lyrics
            )
        }
    }

    private func fetchMediaItem(for track: Track) -> MPMediaItem? {
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(
            value: track.id,
            forProperty: MPMediaItemPropertyPersistentID
        )
        query.addFilterPredicate(predicate)
        return query.items?.first
    }

    // MARK: - PLAYBACK

    func play(_ tracks: [Track], startingAt index: Int) {
        let items: [MPMediaItem] = tracks.compactMap { fetchMediaItem(for: $0) }
        guard items.indices.contains(index) else { return }
        let collection = MPMediaItemCollection(items: items)
        player.setQueue(with: collection)
        player.nowPlayingItem = items[index]
        player.play()
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    func nextTrack() {
        player.skipToNextItem()
    }

    func previousTrack() {
        player.skipToPreviousItem()
    }

    func setRepeatMode(_ mode: RepeatMode) {
        switch mode {
        case .off: player.repeatMode = .none
        case .one: player.repeatMode = .one
        case .all: player.repeatMode = .all
        }
    }

    func setShuffleMode(_ enabled: Bool) {
        player.shuffleMode = enabled ? .songs : .off

    }
}
