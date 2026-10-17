//
//  Playlist.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 12/05/2026.
//

import Foundation
import SwiftData

@Model
final class Playlist {
    // MARK: - PROPERTIES

    var id: UUID
    var createdAt: Date
    var name: String
    var songIDs: [String] = []

    // MARK: - INIT

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        songIDs: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.songIDs = songIDs
    }

}
