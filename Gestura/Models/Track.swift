//
//  Track.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//
import Foundation
internal import MediaPlayer

struct Track: Identifiable {
    // MARK: - PROPERTIES

    let id: MPMediaEntityPersistentID
    let title: String
    let artist: String
    let albumTitle: String
    let duration: TimeInterval
    let artwork: MPMediaItemArtwork?
    let dateAdded: Date
    let genre: String
    let lyrics: String?
}
