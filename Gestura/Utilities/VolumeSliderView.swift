//
//  VolumeSliderView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 24/04/2026.
//

internal import MediaPlayer
import SwiftUI

struct VolumeSliderView: UIViewRepresentable {
    // MARK: - VIEW LIFECYCLE

    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView()
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
