//
//  LibraryHubView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct LibraryHubView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var musicLibrary: MusicLibrary

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            if musicLibrary.permissionDenied {
                VStack {
                    ContentUnavailableView(
                        "No Music Access",
                        systemImage: "music.note.slash",
                        description: Text(
                            "Allow Gestura to access your music in Settings."
                        )
                    )
                    Button("Open Settings") {
                        UIApplication.shared.open(
                            URL(string: UIApplication.openSettingsURLString)!
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 20)
                }
            } else {
                List {
                    Section("Application Library") {
                        NavigationLink(
                            destination: FavoritesView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )

                        ) {
                            LibrarySectionCard(
                                title: "Favorites",
                                icon: "star.fill"
                            )
                        }
                        NavigationLink(
                            destination: PlaylistsView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )
                        ) {
                            LibrarySectionCard(
                                title: "Playlists",
                                icon: "list.bullet.rectangle"
                            )
                        }
                        NavigationLink(
                            destination: RecentlyPlayedView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )
                        ) {
                            LibrarySectionCard(
                                title: "Recently Played",
                                icon: "clock.fill"
                            )
                        }
                    }
                    Section("Apple Music Library") {
                        NavigationLink(
                            destination: SongListView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )

                        ) {
                            LibrarySectionCard(
                                title: "Songs",
                                icon: "music.note"
                            )
                        }
                        NavigationLink(
                            destination: ArtistsView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )
                        ) {
                            LibrarySectionCard(
                                title: "Artists",
                                icon: "music.mic"
                            )
                        }
                        NavigationLink(
                            destination: AlbumsView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )
                        ) {
                            LibrarySectionCard(
                                title: "Albums",
                                icon: "square.stack"
                            )
                        }
                        NavigationLink(
                            destination: GenreView(
                                viewModel: viewModel,
                                musicLibrary: musicLibrary
                            )
                        ) {
                            LibrarySectionCard(
                                title: "Genres",
                                icon: "guitars"
                            )
                        }
                    }

                }
                .listStyle(.insetGrouped)
                .navigationTitle("Library")
            }
        }
    }
}
