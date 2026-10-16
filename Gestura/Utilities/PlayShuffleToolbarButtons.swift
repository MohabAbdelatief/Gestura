//
//  PlayShuffleToolbarButtons.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 15/05/2026.
//

import Foundation
import SwiftUI
internal import MusicKit

struct PlayShuffleToolbarButtons: ToolbarContent {
    // MARK: - PROPERTIES

    let songs: [Song]
    let viewModel: PlayerViewModel

    // MARK: - VIEW

    var body: some ToolbarContent {
        if !songs.isEmpty {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    viewModel.setShuffleEnabled(false)
                    if let firstSong = songs.first {
                        viewModel.play(firstSong, in: songs)
                    }
                } label: {
                    Label("Play All", systemImage: "play.fill")
                }

                Button {
                    viewModel.setShuffleEnabled(true)
                    if let randomSong = songs.randomElement() {
                        viewModel.play(randomSong, in: songs)
                    }
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
            }
        }
    }
}
