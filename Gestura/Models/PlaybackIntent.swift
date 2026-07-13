//
//  PlaybackIntent.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 20/05/2026.
//

enum PlaybackIntent {
    case togglePlayPause
    case setFavorite(id: UInt64, isFavorited: Bool)
    case nextTrack
    case previousTrack
}


