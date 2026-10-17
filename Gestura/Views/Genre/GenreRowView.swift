//
//  GenreRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 08/05/2026.
//

internal import MusicKit
import SwiftUI

struct GenreRowView: View {
    // MARK: - PROPERTIES

    let genre: Genre
    let musicLibrary: MusicLibrary

    // MARK: - STATE

    @State private var artwork: Artwork?

    // MARK: - VIEW

    var body: some View {
        HStack {
            artworkThumbnail
            Text(genre.name)
            Spacer()
        }
        .task {
            let songs = await musicLibrary.songs(in: genre)
            artwork = songs.first(where: { $0.artwork != nil })?.artwork
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkThumbnail: some View {
        Group {
            if let artwork {
                ArtworkImage(artwork, width: 44, height: 44)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "guitars")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
