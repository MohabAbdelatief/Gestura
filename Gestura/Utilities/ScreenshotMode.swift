//
//  ScreenshotMode.swift
//  Gestura
//
//  Demo content for App Store screenshot capture. Active only when the app
//  is launched with the `-GesturaScreenshots` argument, so a normal launch
//  never sees any of this.
//

import SwiftUI
import UIKit
internal import MediaPlayer

enum ScreenshotMode {
    static let isActive = ProcessInfo.processInfo.arguments.contains(
        "-GesturaScreenshots"
    )

    // MARK: - DEMO CATALOG

    struct DemoAlbum {
        let title: String
        let artist: String
        let genre: String
        let colors: [UIColor]
        let symbol: String
        let songs: [(String, TimeInterval)]
    }

    private static let albums: [DemoAlbum] = [
        DemoAlbum(
            title: "Neon Skyline",
            artist: "Nova Waves",
            genre: "Electronic",
            colors: [
                UIColor(red: 0.35, green: 0.15, blue: 0.65, alpha: 1),
                UIColor(red: 0.95, green: 0.35, blue: 0.55, alpha: 1),
            ],
            symbol: "waveform",
            songs: [
                ("Midnight Drive", 227), ("City of Glass", 251),
                ("Afterglow", 198), ("Signal Lost", 243),
            ]
        ),
        DemoAlbum(
            title: "Golden Hour",
            artist: "Cedar & Pine",
            genre: "Indie",
            colors: [
                UIColor(red: 0.95, green: 0.60, blue: 0.20, alpha: 1),
                UIColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 1),
            ],
            symbol: "sun.max.fill",
            songs: [
                ("Open Roads", 212), ("Paper Lanterns", 189),
                ("Wildflower", 234), ("Slow Morning", 205),
            ]
        ),
        DemoAlbum(
            title: "Blue Hour",
            artist: "Mila Reyes",
            genre: "Pop",
            colors: [
                UIColor(red: 0.10, green: 0.45, blue: 0.75, alpha: 1),
                UIColor(red: 0.20, green: 0.80, blue: 0.75, alpha: 1),
            ],
            symbol: "sparkles",
            songs: [
                ("Gravity", 201), ("Talk to Me", 218),
                ("Fireproof", 195), ("Undertow", 226),
            ]
        ),
        DemoAlbum(
            title: "Velvet Groove",
            artist: "The Marlowe Trio",
            genre: "Jazz",
            colors: [
                UIColor(red: 0.45, green: 0.28, blue: 0.15, alpha: 1),
                UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1),
            ],
            symbol: "music.quarternote.3",
            songs: [
                ("Smoke Rings", 312), ("Corner Booth", 287),
                ("Blue in Amber", 264), ("Last Call", 295),
            ]
        ),
        DemoAlbum(
            title: "Ember",
            artist: "Echo Atlas",
            genre: "Rock",
            colors: [
                UIColor(red: 0.55, green: 0.10, blue: 0.12, alpha: 1),
                UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1),
            ],
            symbol: "flame.fill",
            songs: [
                ("Static Hearts", 233), ("Kerosene", 208),
                ("Northern Line", 247), ("Falling Slow", 221),
            ]
        ),
    ]

    private static let demoLyrics = """
        Streetlights hum a quiet tune
        The city breathes below the moon
        We ride the wire from dusk to dawn
        Chasing every light that's on

        Hold the wheel and keep it steady
        Skyline glowing, hearts are ready
        Every signal points us home
        Through the neon, never alone
        """

    static let demoTracks: [Track] = {
        var tracks: [Track] = []
        var id: UInt64 = 1
        for (albumIndex, album) in albums.enumerated() {
            let art = makeArtwork(
                colors: album.colors,
                symbol: album.symbol
            )
            for (songIndex, song) in album.songs.enumerated() {
                tracks.append(
                    Track(
                        id: id,
                        title: song.0,
                        artist: album.artist,
                        albumTitle: album.title,
                        duration: song.1,
                        artwork: art,
                        dateAdded: Date(
                            timeIntervalSinceNow: -Double(
                                (albumIndex * 4 + songIndex) * 86_400
                            )
                        ),
                        genre: album.genre,
                        lyrics: id == 1 ? demoLyrics : nil
                    )
                )
                id += 1
            }
        }
        return tracks
    }()

    // MARK: - STAGING

    /// Puts the player into a believable "now playing" state and seeds
    /// favorites / recently played so Home has content.
    @MainActor
    static func stage(player: PlayerViewModel, libraryStore: LibraryStore) {
        let tracks = demoTracks
        guard !tracks.isEmpty else { return }

        for recentID in [5, 9, 13, 2, 17, 10].map(UInt64.init).reversed() {
            libraryStore.addToRecentlyPlayed(id: recentID)
        }
        for favoriteID in [1, 6, 11, 15].map(UInt64.init)
        where !libraryStore.isFavorite(id: favoriteID) {
            libraryStore.addFavorite(id: favoriteID)
        }

        player.stageForScreenshots(
            queue: tracks,
            playingIndex: 0,
            at: 83
        )
    }

    // MARK: - ARTWORK

    private static func makeArtwork(
        colors: [UIColor],
        symbol: String
    ) -> MPMediaItemArtwork {
        let side: CGFloat = 600
        let size = CGSize(width: side, height: side)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let cgColors = colors.map(\.cgColor) as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: cgColors,
                locations: [0, 1]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: side, y: side),
                    options: []
                )
            }

            let config = UIImage.SymbolConfiguration(
                pointSize: side * 0.38,
                weight: .medium
            )
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(
                    UIColor.white.withAlphaComponent(0.85),
                    renderingMode: .alwaysOriginal
                )
            {
                let glyphRect = CGRect(
                    x: (side - glyph.size.width) / 2,
                    y: (side - glyph.size.height) / 2,
                    width: glyph.size.width,
                    height: glyph.size.height
                )
                glyph.draw(in: glyphRect)
            }
        }
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }
}
