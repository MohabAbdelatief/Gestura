//
//  PlaybackIntent.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 20/05/2026.
//

internal import MusicKit

enum PlaybackIntent {
    case togglePlayPause
    case setFavorite(id: MusicItemID, isFavorited: Bool)
    case nextTrack
    case previousTrack
}


