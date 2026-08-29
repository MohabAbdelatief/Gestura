//
//  GesturaTabView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct GesturaTabView: View {
    // MARK: - STATE
    // Whether the recognizer screen is currently on-screen. Gates scenePhase
    // resume so we don't start the camera while another tab is showing.
    @State private var isRecognizerVisible: Bool = false

    // MARK: - PROPERTY WRAPPED OBJECTS
    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var gestureViewModel: GestureViewModel
    @ObservedObject var musicLibrary: MusicLibrary
    @ObservedObject private var libraryStore = LibraryStore.shared
    // MARK: - APP STORAGE
    @AppStorage(GesturaSettings.enabledKey) private var gesturaEnabled: Bool =
        GesturaSettings.enabledDefault

    // MARK: - ENVIRONMENT

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var dispatcher: PlaybackIntentDispatcher

    // MARK: - VIEW
    var body: some View {
        Group {
            if gesturaEnabled {
                Group {
                    if let reason = gestureViewModel.unavailableReason {
                        recoveryView(for: reason)
                    } else {
                        activeRecognizerView
                    }
                }
                .onAppear {
                    isRecognizerVisible = true
                    UIApplication.shared.isIdleTimerDisabled = true
                    Task { await gestureViewModel.start() }
                }
                .onDisappear {
                    isRecognizerVisible = false
                    UIApplication.shared.isIdleTimerDisabled = false
                    gestureViewModel.stop()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // Stop the camera when the app leaves the foreground
                    // (backs the privacy promise that recording stops) and
                    // resume on return — but only while this screen shows.
                    // .inactive is transient (permission dialog, Control
                    // Center) so we ignore it and let interruption handling
                    // in the service cover in-app interruptions.
                    guard isRecognizerVisible else { return }
                    switch newPhase {
                    case .active:
                        UIApplication.shared.isIdleTimerDisabled = true
                        Task { await gestureViewModel.start() }
                    case .background:
                        UIApplication.shared.isIdleTimerDisabled = false
                        gestureViewModel.stop()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
            } else {
                ContentUnavailableView {
                    Label(
                        "Gesture Control Is Off",
                        systemImage: "hand.raised.slash"
                    )
                } description: {
                    Text(
                        "Turn it back on to control playback without touching your phone."
                    )
                } actions: {
                    Button("Turn On Gesture Control") { gesturaEnabled = true }
                        .buttonStyle(.borderedProminent)
                }
            }

        }
    }

    @ViewBuilder
    private var gestureFlashZone: some View {
        if let gesture = gestureViewModel.lastDetectedGesture {
            VStack(spacing: 12) {
                Image(systemName: gesture.sfSymbolName)
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                Text(gesture.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .transition(.scale.combined(with: .opacity))
        } else if gestureViewModel.liveStatus == .handDetected {
            VStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                Text("Hand detected")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Hold a gesture to control playback")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .transition(.scale.combined(with: .opacity))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "eye")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse, options: .repeating)
                Text("Hold your hand up to the camera")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var artworkView: some View {
        if let track = viewModel.currentTrack {
            ArtworkView(
                artwork: track.artwork,
                persistentID: track.id,
                size: 600
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var songInfoRow: some View {
        if let track = viewModel.currentTrack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(track.artist)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    let isFavorited = libraryStore.isFavorite(id: track.id)
                    dispatcher.execute(
                        .setFavorite(
                            id: track.id,
                            isFavorited: !isFavorited
                        )
                    )
                } label: {
                    Image(
                        systemName: libraryStore.isFavorite(id: track.id)
                            ? "star.fill" : "star"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        libraryStore.isFavorite(id: track.id)
                            ? .primary : .secondary
                    )
                    .padding(12)
                    .glassEffect(.regular, in: Circle())
                }
            }
            .padding(.horizontal, 24)
        }
    }

    /// Shown on the recognizer when nothing is playing. `artworkView` and
    /// `songInfoRow` both collapse to nothing without a track, so without this
    /// the screen the app now opens to would be blank — and it wouldn't say
    /// that an open palm starts playback from here.
    @ViewBuilder
    private var idlePrompt: some View {
        switch viewModel.pendingStart {
        case .resume(let track):
            idleMessage(
                "hand.raised.fill",
                "Ready when you are",
                "Hold up an open palm to play \(track.title)."
            )
        case .shuffleLibrary:
            idleMessage(
                "shuffle",
                "Ready when you are",
                "Hold up an open palm to shuffle your library."
            )
        case .libraryLoading:
            idleMessage(
                "hourglass",
                "Loading your library",
                "One moment."
            )
        case .libraryEmpty:
            idleMessage(
                "music.note",
                "No Music Yet",
                "Add songs to your library in the Apple Music app, then come back."
            )
        case .accessDenied:
            idleMessage(
                "music.note.slash",
                "No Music Access",
                "Allow Gestura to access your music in Settings."
            )
        }
    }

    private func idleMessage(
        _ symbol: String,
        _ title: String,
        _ detail: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var activeRecognizerView: some View {
        VStack(spacing: 24) {
            if viewModel.currentTrack == nil {
                idlePrompt
            } else {
                artworkView
                songInfoRow
            }
            Spacer()
            gestureFlashZone
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.75),
                    value: gestureViewModel.lastDetectedGesture
                )
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.75),
                    value: gestureViewModel.liveStatus
                )
            Spacer()
        }
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private func recoveryView(
        for reason: GestureViewModel.UnavailableReason
    ) -> some View {
        switch reason {
        case .cameraDenied:
            VStack {
                ContentUnavailableView(
                    "Camera Access Needed",
                    systemImage: "video.slash",
                    description: Text(
                        "Gestura uses the front camera to read your hand gestures. Allow camera access in Settings to control playback hands-free."
                    )
                )
                Button("Open Settings") {
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!
                    )
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 20)
            }
        case .modelUnavailable:
            ContentUnavailableView(
                "Gesture Control Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(
                    "Gesture recognition couldn't start on this device. The rest of Gestura still works normally."
                )
            )
        }
    }
}

// MARK: - HELPER VIEWS

#Preview {
    let musicLibrary = MusicLibrary()
    let player = PlayerViewModel(musicLibrary: musicLibrary)
    let feedback = FeedbackCenter()
    let dispatcher = PlaybackIntentDispatcher(
        player: player,
        library: .shared,
        feedback: feedback
    )
    let gestureVM = GestureViewModel(dispatcher: dispatcher, player: player)
    GesturaTabView(
        viewModel: player,
        gestureViewModel: gestureVM,
        musicLibrary: musicLibrary
    )
}
