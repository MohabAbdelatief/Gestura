//
//  PlaylistRowView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 14/05/2026.
//

import SwiftUI

struct PlaylistRowView: View {
    // MARK: - PROPERTIES

    let playlist: Playlist

    // MARK: - VIEW

    var body: some View {
        HStack(spacing: 12) {
            iconView

            Text(playlist.name)
                .font(.headline)
                .lineLimit(1)

            Spacer()
        }
    }

    // MARK: - HELPER VIEWS

    private var iconView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.blue.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.blue)
            }
    }
}
