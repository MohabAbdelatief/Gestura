//
//  PlayerState.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 18/04/2026.
//
import Foundation

enum PlayerState {
    // MARK: - CASES

    case idle
    case playing(Track)
    case paused(Track)
}
