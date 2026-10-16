//
//  NowPlayingView.swift
//  Gestura
//

internal import MusicKit
import SwiftUI

struct NowPlayingView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject private var volumeManager: VolumeManager
    @ObservedObject private var libraryStore = LibraryStore.shared

    // MARK: - STATE

    @State private var showQueue = false

    // MARK: - ENVIROMENT
    @EnvironmentObject private var dispatcher: PlaybackIntentDispatcher

    // MARK: - INIT

    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self._volumeManager = ObservedObject(
            wrappedValue: viewModel.volumeManager
        )
    }

    // MARK: - VIEW

    var body: some View {
        VStack(spacing: 24) {
            artworkView
            songInfoView
            progressView
            controlsView
            volumeSliderView
            playbackOptionsView
        }
        .padding()
        .sheet(isPresented: $showQueue) {
            QueueView(viewModel: viewModel)
        }
        .overlay(alignment: .bottom) {
            FeedbackHUD()
                .padding(.bottom, 24)
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkView: some View {
        Group {
            if let artwork = viewModel.currentSong?.artwork {
                GeometryReader { proxy in
                    ArtworkImage(artwork, width: proxy.size.width)
                }
            } else {
                ZStack {
                    Rectangle().fill(Color(.systemGray5))
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal)
    }

    private var songInfoView: some View {
        HStack {
            // Same size as the favorite button, so the title stays centred.
            Image(systemName: "star")
                .font(.title2)
                .padding(12)
                .hidden()

            Spacer()
            VStack() {
                Text(viewModel.currentSong?.title ?? "Not Playing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(viewModel.currentSong?.artistName ?? "")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Button {
                guard let songID = viewModel.currentSong?.id else { return }
                let isCurrentlyFavorited = libraryStore.isFavorite(id: songID)
                dispatcher.execute(
                    .setFavorite(
                        id: songID,
                        isFavorited: !isCurrentlyFavorited
                    )
                )
            } label: {
                let isFavorited =
                    viewModel.currentSong
                    .map { libraryStore.isFavorite(id: $0.id) } ?? false
                Image(systemName: isFavorited ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(isFavorited ? .primary : .secondary)
                    .padding(12)
                    .glassEffect(.regular, in: Circle())
            }
            .accessibilityLabel(
                (viewModel.currentSong
                    .map { libraryStore.isFavorite(id: $0.id) } ?? false)
                    ? "Remove from favorites" : "Add to favorites"
            )

        }
        .padding(.horizontal)
    }

    private var progressView: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: {
                        viewModel.isScrubbing
                            ? viewModel.scrubTime
                            : viewModel.currentTime
                    },
                    set: { newValue in
                        if !viewModel.isScrubbing {
                            viewModel.startScrubbing()
                        }
                        viewModel.scrub(to: newValue)
                    }
                ),
                in: 0...(viewModel.currentSong?.duration ?? 1),
                onEditingChanged: { editing in
                    if !editing {
                        viewModel.endScrubbing()
                    }
                }
            )
            .foregroundStyle(.primary)
            .sliderThumbVisibility(.hidden)
            .accessibilityLabel("Playback position")

            HStack {
                Text(
                    formatTime(
                        viewModel.isScrubbing
                            ? viewModel.scrubTime
                            : viewModel.currentTime
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text(formatTime(viewModel.currentSong?.duration ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var controlsView: some View {
        HStack {
            Button {
                viewModel.previousTrack()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Previous track")

            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(
                    systemName: viewModel.isPlaying
                        ? "pause.fill" : "play.fill"
                )
                .font(.title)
                .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            Button {
                viewModel.nextTrack()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Next track")

        }
        .padding(.horizontal)

    }

    private var volumeSliderView: some View {

        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Slider(
                value: Binding(
                    get: { volumeManager.volume },
                    set: { newValue in volumeManager.setVolume(newValue) }
                ),
                in: 0...1
            )
            .sliderThumbVisibility(.hidden)
            .accessibilityLabel("Volume")

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
        .padding(.top, 15)
    }

    private var playbackOptionsView: some View {
        HStack {
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.isShuffleEnabled ? .primary : .secondary
                    )
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Shuffle")
            .accessibilityValue(viewModel.isShuffleEnabled ? "On" : "Off")

            Button {
                showQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Queue")

            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(
                    systemName: viewModel.repeatMode == .one
                        ? "repeat.1" : "repeat"
                )
                .font(.title2)
                .foregroundStyle(
                    viewModel.repeatMode == .off ? .secondary : .primary
                )
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Repeat")
            .accessibilityValue(
                viewModel.repeatMode == .off
                    ? "Off"
                    : viewModel.repeatMode == .one
                        ? "Current track" : "All tracks"
            )
        }
        .padding(.horizontal)
    }

}

// MARK: - PREVIEW

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)
    let feedback = FeedbackCenter()
    let dispatcher = PlaybackIntentDispatcher(
        player: viewModel,
        library: .shared,
        feedback: feedback
    )
    NowPlayingView(viewModel: viewModel)
        .environmentObject(dispatcher)
        .environmentObject(feedback)
}
