//
//  PlayShuffleToolbarButtons.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 15/05/2026.
//

import Foundation
import SwiftUI

struct PlayShuffleToolbarButtons: ToolbarContent {
    // MARK: - PROPERTIES

    let tracks: [Track]
    let viewModel: PlayerViewModel

    // MARK: - VIEW

    var body: some ToolbarContent {
        if !tracks.isEmpty {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    viewModel.setShuffleEnabled(false)
                    if let firstTrack = tracks.first {
                        viewModel.play(firstTrack, in: tracks)
                    }
                } label: {
                    Label("Play All", systemImage: "play.fill")
                }

                Button {
                    viewModel.setShuffleEnabled(true)
                    if let randomTrack = tracks.randomElement() {
                        viewModel.play(randomTrack, in: tracks)
                    }
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
            }
        }
    }
}
