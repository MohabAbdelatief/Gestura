//
//  Genre.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 08/05/2026.
//

import Foundation
internal import MediaPlayer

struct Genre: Identifiable {
    // MARK: - PROPERTIES

    let name: String
    let tracks: [Track]

    // MARK: - COMPUTED PROPERTIES

    var id: String { name }

    var artwork: MPMediaItemArtwork? {
        tracks.first(where: { $0.artwork != nil })?.artwork
    }
}
