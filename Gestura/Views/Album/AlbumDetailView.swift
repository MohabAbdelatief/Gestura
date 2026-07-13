//
//  AlbumDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

internal import MediaPlayer
import SwiftUI

struct AlbumDetailView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel

    // MARK: - PROPERTIES

    let album: Album

    // MARK: - VIEW

    var body: some View {
        VStack {
            List {
                artworkHeader
                    .shadow(radius: 6)
                ForEach(album.tracks) { song in
                    Button {
                        viewModel.play(song, in: album.tracks)
                    } label: {
                        SongRowView(track: song, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(album.title)
        .toolbar {
            PlayShuffleToolbarButtons(
                tracks: album.tracks,
                viewModel: viewModel
            )
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkHeader: some View {
        Group {
            if let image = album.artwork?.image(
                at: CGSize(width: 400, height: 400)
            ) {
                Image(uiImage: image)
                    .resizable()
                    .cornerRadius(16)
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)

            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image(systemName: "square.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
