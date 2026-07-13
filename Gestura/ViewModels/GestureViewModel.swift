//
//  GestureViewModel.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 25/05/2026.
//

import AudioToolbox
import Combine
import Foundation
import QuartzCore
import SwiftUI

@MainActor
final class GestureViewModel: ObservableObject {
    // MARK: - PUBLISHED PROPERTIES

    @Published var lastDetectedGesture: Gesture?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var unavailableReason: UnavailableReason?
    @Published private(set) var liveStatus: LiveStatus = .idle

    // MARK: - TYPES

    /// Why the recognizer couldn't run, surfaced to the recovery UI. `nil`
    /// means no failure (either running, or simply not started yet).
    enum UnavailableReason: Equatable {
        case cameraDenied
        case modelUnavailable
    }

    /// What the camera currently sees, for the live framing / no-hand UI.
    /// `.idle` = running but no frame processed yet (or stopped).
    enum LiveStatus: Equatable {
        case idle
        case noHand
        case handDetected
    }

    // MARK: - PROPERTIES

    private let service = GestureRecognitionService()
    private let dispatcher: PlaybackIntentDispatcher
    private let player: PlayerViewModel
    private var consumerTask: Task<Void, Never>?
    private var statusConsumerTask: Task<Void, Never>?
    private var flashResetTask: Task<Void, Never>?

    // Hold-duration tracking (4.6)
    private var currentlyHeldGesture: Gesture?
    private var holdStartTime: CFTimeInterval?
    private var hasFiredForCurrentHold: Bool = false

    // Cool-down tracking (4.7)
    private var lastFiredAt: [Gesture: CFTimeInterval] = [:]

    // Flash visual duration (matches design memory)
    private let flashDuration: Duration = .milliseconds(1500)

    // Audio confirmation for the "Detection Chime" setting. System "Tink"
    // sound; mixes with music without ducking. Key mirrors the @AppStorage
    // in SettingsTabView. (Bundling a custom .caf is a v1.x polish target.)
    private let chimeEnabledKey = "detectionChimeEnabled"
    private let detectionChimeSoundID: SystemSoundID = 1057

    // MARK: - INIT

    init(dispatcher: PlaybackIntentDispatcher, player: PlayerViewModel) {
        self.dispatcher = dispatcher
        self.player = player
    }

    // MARK: - LIFECYCLE

    func start() async {
        guard !isRunning else { return }
        isRunning = true
        unavailableReason = nil
        liveStatus = .idle

        let result = await service.start()
        switch result {
        case .started:
            break
        case .cameraDenied:
            isRunning = false
            unavailableReason = .cameraDenied
            return
        case .modelUnavailable:
            isRunning = false
            unavailableReason = .modelUnavailable
            return
        }

        // stop() may have run while we awaited service.start() (e.g. the user
        // navigated away). If so, don't spin up the consumer.
        guard isRunning else { return }

        // The consumer Task is created once for the lifetime of this view
        // model. AsyncStream can only be iterated once, so cancelling the
        // task on stop() and recreating it on start() would leave the new
        // iterator reading a dead stream. Instead we keep the consumer
        // alive across stop/start cycles and gate work inside handle() on
        // isRunning. We capture the stream directly so the Task only
        // holds a weak reference to self (no retain cycle).
        guard consumerTask == nil else { return }
        consumerTask = Task { [weak self, stream = service.detectionStream] in
            for await detection in stream {
                self?.handle(detection: detection)
            }
        }
        statusConsumerTask = Task {
            [weak self, stream = service.statusStream] in
            for await status in stream {
                self?.handle(status: status)
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        liveStatus = .idle
        // Note: consumerTask is intentionally NOT cancelled here. See start().
        flashResetTask?.cancel()
        flashResetTask = nil
        lastDetectedGesture = nil
        currentlyHeldGesture = nil
        holdStartTime = nil
        hasFiredForCurrentHold = false
        service.stop()
    }

    // MARK: - DETECTION HANDLING

    private func handle(detection: GestureDetection) {
        // Drop any frame that arrives while we're stopped (e.g. an in-flight
        // detection that landed after stop() flipped isRunning to false).
        guard isRunning else { return }

        let now = CACurrentMediaTime()
        let settings = RecognizerSensitivity.current().settings

        if detection.gesture == currentlyHeldGesture {
            // Continuing to hold the same gesture.
            guard !hasFiredForCurrentHold,
                  let start = holdStartTime,
                  (now - start) >= settings.holdDuration
            else { return }

            // Hold threshold reached. Cool-down check before firing.
            if let lastFire = lastFiredAt[detection.gesture],
               (now - lastFire) < settings.cooldown {
                // Still cooling down for this gesture. Mark this hold as
                // handled so we don't retry every frame while held.
                hasFiredForCurrentHold = true
                return
            }

            // Fire.
            hasFiredForCurrentHold = true
            lastFiredAt[detection.gesture] = now
            fire(gesture: detection.gesture)
        } else {
            // New gesture beginning. Reset hold tracking.
            currentlyHeldGesture = detection.gesture
            holdStartTime = now
            hasFiredForCurrentHold = false
        }
    }

    private func handle(status: GestureRecognitionService.FrameStatus) {
        // Drop frames that land after stop().
        guard isRunning else { return }
        switch status {
        case .noHand:
            liveStatus = .noHand
        case .handDetected:
            liveStatus = .handDetected
        }
    }

    // MARK: - DISPATCH

    private func fire(gesture: Gesture) {
        // Set the flash state for the UI.
        lastDetectedGesture = gesture

        // Audio confirmation, if enabled. Read the key live — @AppStorage is a
        // SwiftUI View wrapper, so the view model reads UserDefaults directly.
        if UserDefaults.standard.bool(forKey: chimeEnabledKey) {
            AudioServicesPlaySystemSound(detectionChimeSoundID)
        }

        // Reset the flash after the configured duration.
        flashResetTask?.cancel()
        flashResetTask = Task { [weak self] in
            try? await Task.sleep(for: self?.flashDuration ?? .milliseconds(1500))
            guard !Task.isCancelled else { return }
            self?.lastDetectedGesture = nil
        }

        // Dispatch the corresponding playback intent.
        guard let intent = intent(for: gesture) else { return }
        dispatcher.execute(intent)
    }

    private func intent(for gesture: Gesture) -> PlaybackIntent? {
        switch gesture {
        case .openPalm:
            return .togglePlayPause
        case .pointRight:
            return .nextTrack
        case .pointLeft:
            return .previousTrack
        case .thumbsUp:
            guard let trackID = player.currentTrack?.id else { return nil }
            return .setFavorite(id: trackID, isFavorited: true)
        case .thumbsDown:
            guard let trackID = player.currentTrack?.id else { return nil }
            return .setFavorite(id: trackID, isFavorited: false)
        }
    }
}
