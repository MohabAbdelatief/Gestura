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
        activateAudioSession()
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
    private func activateAudioSession() {
        Task.detached(priority: .userInitiated) { [weak self] in
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                await log(
                    "✅ Session activated. outputVolume:",
                    session.outputVolume
                )
            } catch {
                await log("❌ Session error:", error)
            }
            let current = session.outputVolume
            guard let self else { return }
            await MainActor.run { self.volume = current }
        }
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
