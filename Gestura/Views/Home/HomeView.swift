//
//  HomeView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 15/05/2026.
//

internal import MusicKit
import SwiftUI

struct HomeView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    // 1. A state flag for the sheet
    @State private var showSettings = false

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - SUBSCRIPTION

    @State private var subscription: MusicSubscription?
    @State private var showSubscriptionOffer = false

    private let subscriptionOfferOptions = MusicSubscriptionOffer.Options(
        messageIdentifier: .playMusic
    )

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            HStack {
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .glassEffect(.regular, in: Circle())
                }
                .buttonStyle(.plain)

            }
            .padding()

            if let subscription, subscription.canBecomeSubscriber {
                musicSubscriptionButton
            }

            Group {
                if musicLibrary.permissionDenied {
                    musicAccessDeniedView
                } else if isLibraryEmpty {
                    emptyLibraryView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if !recentlyPlayedSongs.isEmpty {
                                continueListeningSection
                            }

                            if !favoriteSongs.isEmpty {
                                favoritesSection
                            }

                            browseLibrarySection
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showSettings) {
                SettingsTabView(viewModel: viewModel)
            }
            .task(id: musicLibrary.hasLoaded) {
                subscription = try? await MusicSubscription.current
                for await update in MusicSubscription.subscriptionUpdates {
                    subscription = update
                }
            }
        }
    }

    // MARK: - HELPER VIEWS

    private var musicSubscriptionButton: some View {
        Button("Subscribe to Apple Music", systemImage: "music.note") {
            showSubscriptionOffer = true
        }
        .buttonStyle(.borderedProminent)
        .musicSubscriptionOffer(
            isPresented: $showSubscriptionOffer,
            options: subscriptionOfferOptions
        )
    }

    private var isLibraryEmpty: Bool {
        musicLibrary.hasLoaded && musicLibrary.songs.isEmpty
    }

    private var emptyLibraryView: some View {
        ContentUnavailableView {
            Label("No Music Yet", systemImage: "music.note")
        } description: {
            Text("Add songs to your library in the Apple Music app, then come back.")
        } actions: {
            Button("Refresh") { musicLibrary.loadSongs() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var musicAccessDeniedView: some View {
        ContentUnavailableView {
            Label("No Music Access", systemImage: "music.note.slash")
        } description: {
            Text("Allow Gestura to access your music in Settings.")
        } actions: {
            Button("Open Settings") {
                UIApplication.shared.open(
                    URL(string: UIApplication.openSettingsURLString)!
                )
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var continueListeningSection: some View {
        songSection(
            title: "Continue Listening",
            songs: recentlyPlayedSongs,
            size: HomeLayout.featuredCardSize
        )
    }

    private var favoritesSection: some View {
        songSection(
            title: "What You Love",
            songs: favoriteSongs,
            size: HomeLayout.compactCardSize
        )
    }

    private var browseLibrarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Library")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            horizontalScroll {
                HStack(spacing: 16) {
                    ForEach(BrowseDestination.allCases) { destination in
                        browseCard(for: destination)
                    }
                }
            }
        }
    }

    private func songSection(
        title: String,
        songs: [Song],
        size: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            horizontalScroll {
                HStack(spacing: 16) {
                    ForEach(songs) { song in
                        songCard(for: song, in: songs, size: size)
                    }
                }
            }
        }
    }

    private func songCard(
        for song: Song,
        in songs: [Song],
        size: CGFloat
    ) -> some View {
        Button {
            viewModel.play(song, in: songs)
        } label: {
            ZStack(alignment: .bottomLeading) {
                artworkOrPlaceholder(for: song, size: size)
                songCardTextOverlay(for: song, width: size)
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(
                color: HomeLayout.cardShadowColor,
                radius: HomeLayout.cardShadowRadius,
                x: 0,
                y: HomeLayout.cardShadowYOffset
            )
        }
        .buttonStyle(.plain)
    }

    private func artworkOrPlaceholder(for song: Song, size: CGFloat) -> some View {
        Group {
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: size, height: size)
            } else {
                ZStack {
                    Rectangle().fill(Color(.systemGray5))
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func songCardTextOverlay(for song: Song, width: CGFloat)
        -> some View
    {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(song.artistName)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .shadow(radius: 2)
        .padding(10)
        .frame(width: width, alignment: .leading)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    private func browseCard(for destination: BrowseDestination) -> some View {
        NavigationLink {
            destination.makeDestination(
                viewModel: viewModel,
                musicLibrary: musicLibrary
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                placeholderBackground(
                    icon: destination.icon,
                    iconSize: 58
                )
                .frame(
                    width: HomeLayout.compactCardSize,
                    height: HomeLayout.compactCardSize
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(
                    color: HomeLayout.cardShadowColor,
                    radius: HomeLayout.cardShadowRadius,
                    x: 0,
                    y: HomeLayout.cardShadowYOffset
                )

                Text(destination.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            .frame(width: HomeLayout.compactCardSize, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func placeholderBackground(icon: String, iconSize: CGFloat)
        -> some View
    {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray5))

            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(.secondary)
        }
    }

    /// Horizontal scroll that lets card shadows extend past the
    /// ScrollView's frame instead of being clipped.
    private func horizontalScroll<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content()
        }
        .scrollClipDisabled()
    }

    // MARK: - COMPUTED PROPERTIES

    private var recentlyPlayedSongs: [Song] {
        musicLibrary.recentlyPlayedSongs
    }

    private var favoriteSongs: [Song] {
        musicLibrary.favoriteSongs
    }

    // MARK: - LAYOUT

    private enum HomeLayout {
        static let cardShadowColor = Color.black.opacity(0.18)
        static let cardShadowRadius: CGFloat = 8
        static let cardShadowYOffset: CGFloat = 4

        static let featuredCardSize: CGFloat = 300
        static let compactCardSize: CGFloat = 150
    }

    // MARK: - BROWSE DESTINATIONS

    private enum BrowseDestination: String, CaseIterable, Identifiable {
        case playlists, songs, artists, albums, genres

        var id: String { rawValue }

        var title: String {
            switch self {
            case .playlists: "Playlists"
            case .songs: "Songs"
            case .artists: "Artists"
            case .albums: "Albums"
            case .genres: "Genres"
            }
        }

        var icon: String {
            switch self {
            case .playlists: "list.bullet.rectangle"
            case .songs: "music.note"
            case .artists: "music.mic"
            case .albums: "square.stack"
            case .genres: "guitars"
            }
        }

        @ViewBuilder
        func makeDestination(
            viewModel: PlayerViewModel,
            musicLibrary: MusicLibrary
        ) -> some View {
            switch self {
            case .playlists:
                PlaylistsView(
                    viewModel: viewModel,
                    musicLibrary: musicLibrary
                )
            case .songs:
                SongListView(
                    viewModel: viewModel,
                    musicLibrary: musicLibrary
                )
            case .artists:
                ArtistsView(
                    viewModel: viewModel,
                    musicLibrary: musicLibrary
                )
            case .albums:
                AlbumsView(
                    viewModel: viewModel,
                    musicLibrary: musicLibrary
                )
            case .genres:
                GenreView(
                    viewModel: viewModel,
                    musicLibrary: musicLibrary
                )
            }
        }
    }
}

#Preview {
    let musicLibrary = MusicLibrary()
    let viewModel = PlayerViewModel(musicLibrary: musicLibrary)

    HomeView(viewModel: viewModel, musicLibrary: musicLibrary)
}
