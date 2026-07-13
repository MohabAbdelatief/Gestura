//
//  GesturaPrivacyView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 25/05/2026.
//

import SwiftUI

struct GesturaPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gestura uses your iPhone's front camera to recognize hand gestures while a song is playing.")

                Text("**On-device only.**")
                Text("Every frame the camera captures is processed entirely on your iPhone — by Apple's Vision framework for hand detection and an on-device Core ML model for gesture classification. No video data is sent to a server, uploaded, or shared.")

                Text("**Nothing is recorded.**")
                Text("Frames are analyzed in memory and immediately discarded. Gestura does not save photos, video, or any visual data to disk or to your Photo Library.")

                Text("**Camera turns on only when needed.**")
                Text("The camera runs only while the Gestura tab is on screen, a song is loaded, and Gestura is enabled in Settings. Leaving the tab, pausing playback so that no song is loaded, or disabling Gestura immediately stops the camera.")
            }
            .padding()
        }
        .navigationTitle("How Gestura Uses Your Camera")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PREVIEW

#Preview {
    NavigationStack {
        GesturaPrivacyView()
    }
}
