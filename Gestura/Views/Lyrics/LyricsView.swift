//
//  LyricsView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 17/05/2026.
//

import SwiftUI

struct LyricsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    var body: some View {
        if let lyrics = viewModel.currentTrack?.lyrics, !lyrics.isEmpty {
            ScrollView {
                Text(lyrics)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView(
                "No Lyrics",
                systemImage: "quote.bubble",
                description: Text("Current lyrics feature is bad, we are working on a better one.")
            )
        }
    }
}

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)
    LyricsView(viewModel: viewModel)
}
