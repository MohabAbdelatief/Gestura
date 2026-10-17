//
//  AlbumDetailView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 06/05/2026.
//

internal import MusicKit
import SwiftUI

struct AlbumDetailView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - PROPERTIES

    let album: Album
    var isCatalog = false

    // MARK: - STATE

    @State private var catalogSongs: [Song] = []
    @State private var showSubscriptionOffer = false

    // MARK: - COMPUTED PROPERTIES

    private var songs: [Song] {
        isCatalog ? catalogSongs : musicLibrary.songs(in: album)
    }

    private var canPlay: Bool {
        !isCatalog || musicLibrary.subscription?.canPlayCatalogContent == true
    }

    // MARK: - VIEW

    var body: some View {
        VStack {
            List {
                artworkHeader
                    .shadow(radius: 6)
                ForEach(songs) { song in
                    Button {
                        play(song)
                    } label: {
                        SongRowView(
                            song: song,
                            viewModel: viewModel
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(album.title)
        .toolbar {
            if canPlay {
                PlayShuffleToolbarButtons(
                    songs: songs,
                    viewModel: viewModel
                )
            }
        }
        .task {
            if isCatalog {
                catalogSongs = await musicLibrary.catalogSongs(in: album)
            }
        }
        .musicSubscriptionOffer(
            isPresented: $showSubscriptionOffer,
            options: .gestura
        )
    }

    // MARK: - HELPERS

    private func play(_ song: Song) {
        if canPlay {
            viewModel.play(song, in: songs)
        } else {
            showSubscriptionOffer = true
        }
    }

    // MARK: - HELPER VIEWS

    private var artworkHeader: some View {
        Group {
            if let artwork = album.artwork {
                GeometryReader { proxy in
                    ArtworkImage(artwork, width: proxy.size.width)
                        .cornerRadius(16)
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image(systemName: "square.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                    )
            }
        }
    }
}
