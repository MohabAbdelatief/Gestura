//
//  ArtworkLoader.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 16/05/2026.
//

import Combine
import Foundation
internal import MediaPlayer

@MainActor
final class ArtworkLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    private var task: Task<Void, Error>?

    func load(
        artwork: MPMediaItemArtwork?,
        persistentID: MPMediaEntityPersistentID,
        size: Int
    ) {

        if let cached = ArtworkCache.shared.image(for: persistentID, size: size)
        {
            image = cached
            return
        }

        task?.cancel()
        guard let artwork else {
            image = nil
            return
        }

        task = Task { [weak self] in
            try Task.checkCancellation()
            let decoded = artwork.image(at: CGSize(width: size, height: size))

            try Task.checkCancellation()

            if let decoded {
                ArtworkCache.shared.setImage(
                    decoded,
                    for: persistentID,
                    size: size
                )
            }
            self?.image = decoded
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
