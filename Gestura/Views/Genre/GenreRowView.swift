//
//  GenreRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 08/05/2026.
//

internal import MediaPlayer
import SwiftUI

struct GenreRowView: View {
    // MARK: - PROPERTIES

    let genre: Genre

    // MARK: - VIEW

    var body: some View {
        HStack {
            artworkThumbnail
            Text(genre.name)
            Spacer()
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkThumbnail: some View {
        Group {
            if let image = genre.artwork?.image(
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
                        Image(systemName: "guitars")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
