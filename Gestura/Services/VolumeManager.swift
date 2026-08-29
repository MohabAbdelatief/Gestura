//
//  VolumeManager.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 27/04/2026.
//

import AVFoundation
import Combine
import Foundation
internal import MediaPlayer

@MainActor
class VolumeManager: NSObject, ObservableObject {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @Published var volume: Float = 0.0

    // MARK: - PROPERTIES

    private var pollingTask: Task<Void, Never>?
    private let volumeView = MPVolumeView(
        frame: CGRect(x: -1000, y: -1000, width: 1, height: 1)
    )

    // MARK: - INIT

    override init() {
        super.init()
        readInitialVolume()
        startPollingSliderValue()
    }

    // MARK: - FUNCTIONS

    func setVolume(_ newVolume: Float) {

        volume = newVolume

        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                slider.value = newVolume
                break
            }
        }
    }

    // MARK: - HELPERS
    /// Seeds the published volume from the system.
    ///
    /// Deliberately reads without activating a session. `MPMusicPlayerController`
    /// plays out of process, so it owns audio from our point of view — claiming
    /// a non-mixing `.playback` session here only picks a fight we lose (the
    /// console showed the session being interrupted the moment music started),
    /// and it would cut off whatever the user already had playing at launch.
    /// `outputVolume` reads fine without it.
    private func readInitialVolume() {
        volume = AVAudioSession.sharedInstance().outputVolume
    }

    private func startPollingSliderValue() {
        pollingTask?.cancel()
        pollingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // 1. Wait for a foreground-active window, retry up to 2 seconds.
            var window: UIWindow?
            for _ in 0..<20 {
                try? await Task.sleep(for: .milliseconds(100))
                window =
                    (UIApplication.shared.connectedScenes
                    .first { $0.activationState == .foregroundActive }
                    as? UIWindowScene)?.windows.first
                if window != nil { break }
            }
            guard let window else {
                log("❌ Could not find foreground window")
                return
            }
            window.addSubview(self.volumeView)
            log("✅ volumeView attached to window")

            // 2. Wait for UIKit to lay out the MPVolumeSlider subview.
            try? await Task.sleep(for: .milliseconds(500))

            // 3. Find the slider.
            var slider: UISlider?
            for subview in self.volumeView.subviews {
                if let s = subview as? UISlider {
                    slider = s
                    break
                }
            }
            guard let slider else {
                log("❌ Could not find MPVolumeSlider")
                return
            }
            log("✅ Polling started, initial slider value:", slider.value)

            // 4. Poll.
            var lastValue = slider.value
            self.volume = lastValue
            while !Task.isCancelled {
                let current = slider.value
                if abs(current - lastValue) > 0.001 {
                    log("📡 slider changed:", lastValue, "→", current)
                    lastValue = current
                    self.volume = current
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    // MARK: - DEINIT

    deinit {
        pollingTask?.cancel()
        let view = volumeView
        Task {
            @MainActor in
            view.removeFromSuperview()
        }

    }
}
