//
//  AlbumRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

internal import MediaPlayer
import SwiftUI

struct AlbumRowView: View {
    // MARK: - PROPERTIES

    let album: Album

    // MARK: - VIEW

    var body: some View {
        HStack {
            artworkThumbnail
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.headline)
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkThumbnail: some View {
        Group {
            if let image = album.artwork?.image(
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
                        Image(systemName: "square.stack")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
