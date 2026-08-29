//
//  OnboardingStep.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 19/06/2026.
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    // `library` sits second on purpose: someone who only streams from Spotify
    // should find that out before investing in the gesture and camera screens,
    // not after finishing onboarding into an empty library.
    case welcome, library, gestures, camera, done
}
