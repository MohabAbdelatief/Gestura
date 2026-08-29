//
//  OnboardingView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 19/06/2026.

import SwiftUI

struct OnboardingView: View {
    let musicLibrary: MusicLibrary

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding =
        false
    @AppStorage(GesturaSettings.enabledKey) private var gesturaEnabled: Bool =
        GesturaSettings.enabledDefault
    @State private var step: OnboardingStep = .welcome
    @State private var gesturesAppeared = false
    @State private var doneAppeared = false

    var body: some View {
        VStack(spacing: 24) {
            Group {
                switch step {
                case .welcome: welcomeStep
                case .library: libraryStep
                case .gestures: gesturesStep
                case .camera: cameraStep
                case .done: doneStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(step)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )

            progressDots
            navButtons
        }
        .padding()
    }

    // MARK: Steps (placeholders for now)
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse)

            Text("Control your music\nwithout touching your phone")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(
                "Wave a gesture at the camera to play, skip, and favorite — when your hands are full or a voice assistant won't hear you."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            Spacer()
        }
    }
    private var libraryStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Plays your own library")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                infoRow(
                    "music.note.list",
                    "Apple Music",
                    "Songs you've added to your library, including anything downloaded for offline listening."
                )
                infoRow(
                    "arrow.down.circle.fill",
                    "Found automatically",
                    "Audio already synced or purchased on this iPhone shows up on its own — there's nothing to import."
                )
                infoRow(
                    "xmark.circle.fill",
                    "Not Spotify or other streaming apps",
                    "Those services keep playback inside their own apps, so Gestura can't see or control them.",
                    symbolColor: .secondary
                )
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.tint)
                Text(
                    "Library looking empty? Add or download a few songs in **Apple Music** first."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            .padding(.horizontal)

            Spacer()
        }
    }

    private var gesturesStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Five simple gestures")
                .font(.title.bold())
                .padding(.top)

            VStack(spacing: 12) {
                ForEach(Array(Gesture.allCases.enumerated()), id: \.element) {
                    index,
                    gesture in
                    HStack(spacing: 16) {
                        Image(systemName: gesture.sfSymbolName)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(gesture.displayName)
                                .font(.headline)
                            Text(gesture.actionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        .quaternary.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .opacity(gesturesAppeared ? 1 : 0)
                    .offset(y: gesturesAppeared ? 0 : 12)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.08),
                        value: gesturesAppeared
                    )
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "speedometer")
                    .foregroundStyle(.tint)
                Text(
                    "Pick **Relaxed**, **Standard**, or **Snappy** in Settings to change how fast a gesture triggers."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal)
        .onAppear { gesturesAppeared = true }
    }
    private var cameraStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Private by design")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 16) {
                infoRow(
                    "eye.slash.fill",
                    "Nothing is recorded",
                    "The camera reads your hand pose live and discards each frame."
                )
                infoRow(
                    "iphone",
                    "Stays on your phone",
                    "Recognition runs entirely on-device — nothing is uploaded."
                )
                infoRow(
                    "bolt.slash.fill",
                    "Only while you're using it",
                    "The camera turns off the moment you leave the Gestura tab."
                )
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private func infoRow(
        _ symbol: String,
        _ title: String,
        _ detail: String,
        symbolColor: Color = .accentColor
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(symbolColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, value: doneAppeared)

            Text("You're all set")
                .font(.title.bold())

            Text(
                "Gestura controls the music in your library. Make sure you've added songs — and hearted a few favorites — in Apple Music."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button("Start using Gestura") {
                    gesturaEnabled = true
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Maybe later") {
                    gesturaEnabled = false
                    hasCompletedOnboarding = true
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom)
        }
        .onAppear { doneAppeared = true }
    }

    // MARK: Chrome
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.self) { s in
                Circle()
                    .fill(
                        s == step ? Color.accentColor : .secondary.opacity(0.3)
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(s == step ? 1.4 : 1)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6),
                        value: step
                    )
            }
        }
    }

    private var navButtons: some View {
        HStack {
            if step != .welcome { Button("Back") { move(-1) } }
            Spacer()
            if step != .done {
                Button("Next") { move(1) }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func move(_ delta: Int) {
        guard let next = OnboardingStep(rawValue: step.rawValue + delta) else {
            return
        }

        // Each permission is asked for on the way out of the screen that
        // explains it, so the system prompt always arrives with context.
        // Neither denial is fatal: the recognizer's
        // `recoveryView(for: .cameraDenied)` and `musicLibrary.permissionDenied`
        // both handle it later.
        switch (step, delta > 0) {
        case (.library, true):
            Task {
                await musicLibrary.requestAccess()
                withAnimation { step = next }
            }
        case (.camera, true):
            Task {
                _ = await GestureRecognitionService.requestCameraAuthorization()
                withAnimation { step = next }
            }
        default:
            withAnimation { step = next }
        }
    }
}
