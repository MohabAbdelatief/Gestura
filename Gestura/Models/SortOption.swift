//
//  SortOptions.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 07/05/2026.
//

import Foundation

enum SortOption: String, CaseIterable {
    // MARK: - CASES

    case title
    case artist
    case album
    case dateAdded

    // MARK: - COMPUTED PROPERTIES

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .dateAdded: return "Date Added"
        }
    }
}
