//
//  ArtistDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

internal import MusicKit
import SwiftUI

struct ArtistDetailView: View {
    // MARK: - PROPERTIES

    let artist: Artist

    private var songs: [Song] {
        musicLibrary.songs(by: artist)
    }

    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - VIEW

    var body: some View {
        VStack {
            List {
                artworkHeader
                ForEach(songs) { song in
                    Button {
                        viewModel.play(song, in: songs)
                    } label: {
                        SongRowView(song: song, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(artist.name)
        .toolbar {
            PlayShuffleToolbarButtons(songs: songs, viewModel: viewModel)
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkHeader: some View {
        Group {
            if let artwork = artist.artwork {
                GeometryReader { proxy in
                    ArtworkImage(artwork, width: proxy.size.width)
                        .cornerRadius(16)
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image(systemName: "music.mic")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
