//
//  LyricsView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 17/05/2026.
//

import SwiftUI

struct LyricsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            Text(viewModel.currentTrack?.lyrics ?? "")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // NowPlayingView only offers the button for tracks that carry lyrics,
        // but the track can change while this sheet is up. Leave rather than
        // sit on a blank scroll view.
        .onChange(of: viewModel.currentTrack?.lyrics) { _, lyrics in
            if (lyrics ?? "").isEmpty { dismiss() }
        }
    }
}

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)
    LyricsView(viewModel: viewModel)
}
