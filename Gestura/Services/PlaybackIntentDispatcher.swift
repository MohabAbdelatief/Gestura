//
//  PlaybackIntentDispatcher.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 20/05/2026.
//

import Combine
import Foundation

@MainActor
final class PlaybackIntentDispatcher: ObservableObject {
    private let player: PlayerViewModel
    private let library: LibraryStore
    private let feedback: FeedbackCenter

    init(
        player: PlayerViewModel,
        library: LibraryStore,
        feedback: FeedbackCenter
    ) {
        self.player = player
        self.library = library
        self.feedback = feedback
    }

    func execute(_ intent: PlaybackIntent) {
        switch intent {
        case .togglePlayPause:
            switch player.togglePlayPause() {
            case nil:
                switch player.startPlayback() {
                case .started(let track):
                    feedback.show("Playing \(track.title)")
                case .libraryLoading:
                    feedback.show("Loading your library…")
                case .libraryEmpty:
                    feedback.show("No songs in your library")
                case .accessDenied:
                    feedback.show("Music access needed")
                }
            case true?: feedback.show("Playing")
            case false?: feedback.show("Paused")
            }
        case .nextTrack:
            player.nextTrack()
            feedback.show("Next Song")
        case .previousTrack:
            player.previousTrack()
            feedback.show("Previous Song")
        case .setFavorite(let trackID, let shouldBeFavorited):
            let isCurrentlyFavorited = library.isFavorite(id: trackID)
            if isCurrentlyFavorited == shouldBeFavorited {
                if shouldBeFavorited {
                    feedback.show("Already in Favorites")
                } else {
                    feedback.show("Song not in Favorites")
                }
            } else {
                if shouldBeFavorited {
                    library.addFavorite(id: trackID)
                    feedback.show("Added to Favorites")
                } else {
                    library.removeFavorite(id: trackID)
                    feedback.show("Removed from Favorites")
                }
            }
        }

    }
}
