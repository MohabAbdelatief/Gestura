//
//  FeedbackHUD.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 22/05/2026.
//
import SwiftUI

struct FeedbackHUD: View {
    @EnvironmentObject private var feedbackCenter: FeedbackCenter

    var body: some View {
        Group {
            if let message = feedbackCenter.message {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)  
                    Text(message)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect()
                .transition(
                    .move(edge: .bottom).combined(with: .opacity)
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackCenter.message)
    }
}
