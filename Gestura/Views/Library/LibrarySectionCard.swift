//
//  LibrarySectionCard.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct LibrarySectionCard: View {
    // MARK: - PROPERTIES

    let title: String
    let icon: String

    // MARK: - VIEW

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PREVIEW

#Preview {
    LibrarySectionCard(title: "Favorites", icon: "star.fill")
}
