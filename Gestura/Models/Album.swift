//
//  Album.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

import Foundation
internal import MediaPlayer

struct Album: Identifiable {
    // MARK: - PROPERTIES

    let title: String
    let artist: String
    let tracks: [Track]

    // MARK: - COMPUTED PROPERTIES

    var id: String { "\(artist)|\(title)" }

    var artwork: MPMediaItemArtwork? {
        tracks.first(where: { $0.artwork != nil })?.artwork
    }
}
