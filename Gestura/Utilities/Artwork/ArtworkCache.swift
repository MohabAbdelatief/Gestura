//
//  ArtworkCache.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 16/05/2026.
//

import Combine
import Foundation
internal import MediaPlayer
import UIKit

final class ArtworkCacheKey: NSObject {
    let persistentID: MPMediaEntityPersistentID
    let size: Int

    init(persistentID: MPMediaEntityPersistentID, size: Int) {
        self.persistentID = persistentID
        self.size = size
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(persistentID)
        hasher.combine(size)
        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? ArtworkCacheKey {
            return persistentID == rhs.persistentID && size == rhs.size
        }
        return false
    }
}

final class ArtworkCache {
    static let shared = ArtworkCache()
    private let cache = NSCache<ArtworkCacheKey, UIImage>()

    func image(for persistentID: MPMediaEntityPersistentID, size: Int)
        -> UIImage?
    {
        let key = ArtworkCacheKey(persistentID: persistentID, size: size)
        return cache.object(forKey: key)
    }

    func setImage(
        _ image: UIImage,
        for persistentID: MPMediaEntityPersistentID,
        size: Int
    ) {
        let key = ArtworkCacheKey(persistentID: persistentID, size: size)
        let cost = size * size * 4  // bytes, RGBA
        cache.setObject(image, forKey: key, cost: cost)
    }

    private init() {
        cache.totalCostLimit = 50_000_000  // 50 MB
    }

}


