//
//  GenreDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 08/05/2026.
//

internal import MusicKit
import SwiftUI

struct GenreDetailView: View {
    // MARK: - PROPERTIES

    let genre: Genre

    private var songs: [Song] {
        musicLibrary.songs(in: genre)
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
        .navigationTitle(genre.name)
    }

    // MARK: - HELPER VIEWS

    private var artworkHeader: some View {
        Group {
            if let artwork = songs.first(where: { $0.artwork != nil })?.artwork {
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
                        Image(systemName: "guitars")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
