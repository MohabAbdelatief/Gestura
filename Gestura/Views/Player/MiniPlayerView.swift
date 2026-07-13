//
//  MiniPlayerView.swift
//  Gestura
//

internal import MediaPlayer
import SwiftUI

struct MiniPlayerView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel

    // MARK: - PROPERTIES

    var onTap: () -> Void

    // MARK: - VIEW

    var body: some View {
        if let track = viewModel.currentTrack {
            HStack {
                Button {
                    onTap()
                } label: {
                    HStack {
                        if let artwork = track.artwork,
                            let image = artwork.image(
                                at: CGSize(width: 44, height: 44)
                            )
                        {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                )
                        }

                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()  // ← moved INSIDE the button label
                    }
                    .contentShape(Rectangle())  // ← add this line
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(
                        systemName: viewModel.isPlaying
                            ? "pause.fill" : "play.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(.primary)
                }
                Button {
                    viewModel.nextTrack()
                } label: {
                    Image(
                        systemName: "forward.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(.primary)
                }
            }
            .contentShape(Rectangle())
            .padding(12)
        }
    }
}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)
    MiniPlayerView(viewModel: viewModel, onTap: {})
}
