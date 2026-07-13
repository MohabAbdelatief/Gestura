//
//  ArtworkView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 16/05/2026.
//

internal import MediaPlayer
import SwiftUI

struct ArtworkView<Placeholder: View>: View {
    let artwork: MPMediaItemArtwork?
    let persistentID: MPMediaEntityPersistentID
    let size: CGFloat
    let placeholder: () -> Placeholder

    @StateObject private var loader = ArtworkLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder()
            }
        }
        .task(id: persistentID) {
            loader.load(
                artwork: artwork,
                persistentID: persistentID,
                size: Int(size)
            )
        }
    }
}

extension ArtworkView where Placeholder == DefaultArtworkPlaceholder {
    init(
        artwork: MPMediaItemArtwork?,
        persistentID: MPMediaEntityPersistentID,
        size: CGFloat
    ) {
        self.init(
            artwork: artwork,
            persistentID: persistentID,
            size: size,
            placeholder: { DefaultArtworkPlaceholder() }
        )
    }
}

struct DefaultArtworkPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color(.systemGray5))
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }
}
