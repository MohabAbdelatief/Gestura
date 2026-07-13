//
//  ArtistRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

internal import MediaPlayer
import SwiftUI

struct ArtistRowView: View {
    // MARK: - PROPERTIES

    let artist: Artist

    // MARK: - VIEW

    var body: some View {
        HStack {
            artworkThumbnail
            Text(artist.name)
            Spacer()
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkThumbnail: some View {
        Group {
            if let image = artist.artwork?.image(
                at: CGSize(width: 44, height: 44)
            ) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.mic")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
