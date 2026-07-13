//
//  Gesture.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 24/05/2026.
//

import Foundation

enum Gesture: String, CaseIterable {
    case openPalm = "open_palm"
    case pointRight = "point_right"
    case pointLeft = "point_left"
    case thumbsUp = "thumbs_up"
    case thumbsDown = "thumbs_down"

    var displayName: String {
        switch self {
        case .openPalm: return "Open Palm"
        case .pointRight: return "Point Right"
        case .pointLeft: return "Point Left"
        case .thumbsUp: return "Thumbs Up"
        case .thumbsDown: return "Thumbs Down"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .openPalm: return "hand.raised.fill"
        case .pointRight: return "hand.point.right.fill"
        case .pointLeft: return "hand.point.left.fill"
        case .thumbsUp: return "hand.thumbsup.fill"
        case .thumbsDown: return "hand.thumbsdown.fill"
        }
    }

    var actionDescription: String {
        switch self {
        case .openPalm:    return "Play / Pause"
        case .pointRight:  return "Next Track"
        case .pointLeft:   return "Previous Track"
        case .thumbsUp:    return "Add to Favorites"
        case .thumbsDown:  return "Remove from Favorites"
        }
    }
}
