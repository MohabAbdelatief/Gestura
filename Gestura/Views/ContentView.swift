import SwiftUI

struct ContentView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @StateObject private var viewModel: PlayerViewModel
    @StateObject private var musicLibrary: MusicLibrary
    @StateObject private var feedbackCenter: FeedbackCenter
    @StateObject private var dispatcher: PlaybackIntentDispatcher
    @StateObject private var gestureViewModel: GestureViewModel

    // MARK: - APP STORAGE

    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled:
        Bool = true
    @AppStorage(GesturaSettings.enabledKey) private var gesturaEnabled: Bool =
        GesturaSettings.enabledDefault
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding =
        false

    // MARK: - STATE

    @State private var showNowPlaying: Bool = false
    @State private var selectedTab: AppTab = .home

    // MARK: - INIT

    init() {
        let musicLibrary = MusicLibrary()
        _musicLibrary = StateObject(wrappedValue: musicLibrary)

        let viewModel = PlayerViewModel(musicLibrary: musicLibrary)
        _viewModel = StateObject(wrappedValue: viewModel)

        let feedbackCenter = FeedbackCenter()
        _feedbackCenter = StateObject(wrappedValue: feedbackCenter)

        let dispatcher = PlaybackIntentDispatcher(
            player: viewModel,
            library: .shared,
            feedback: feedbackCenter
        )
        _dispatcher = StateObject(wrappedValue: dispatcher)

        let gestureViewModel = GestureViewModel(
            dispatcher: dispatcher,
            player: viewModel
        )
        _gestureViewModel = StateObject(wrappedValue: gestureViewModel)
    }

    // MARK: - LAYOUT CONSTANTS

    private enum HUDLayout {
        static let tabBarHeight: CGFloat = 80
        static let miniPlayerHeight: CGFloat = 62
        static let bottomGap: CGFloat = 8
    }

    private var hudBottomPadding: CGFloat {
        HUDLayout.tabBarHeight
            + (viewModel.currentTrack == nil ? 0 : HUDLayout.miniPlayerHeight)
            + HUDLayout.bottomGap
    }

    // MARK: - VIEW
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(viewModel: viewModel, musicLibrary: musicLibrary)
            }

            Tab("Gestura", systemImage: "hand.raised", value: .gestura) {
                GesturaTabView(
                    viewModel: viewModel,
                    gestureViewModel: gestureViewModel,
                    musicLibrary: musicLibrary
                )
            }

            Tab(value: .search, role: .search) {
                SearchTabView(viewModel: viewModel, musicLibrary: musicLibrary)
            }
            Tab("Library", systemImage: "music.note.list", value: .library) {
                LibraryHubView(viewModel: viewModel, musicLibrary: musicLibrary)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: viewModel.currentTrack != nil) {
            MiniPlayerView(
                viewModel: viewModel,
                onTap: { showNowPlaying = true }
            )
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView(viewModel: viewModel)
        }
        .fullScreenCover(
            isPresented: .init(
                get: { !hasCompletedOnboarding },
                set: { _ in }  // dismissal happens only via the flag
            )
        ) {
            OnboardingView()
        }
        .overlay(alignment: .bottom) {
            FeedbackHUD()
                .padding(.horizontal, 24)
                .padding(.bottom, hudBottomPadding)
        }
        .environmentObject(feedbackCenter)
        .environmentObject(dispatcher)
        .sensoryFeedback(.success, trigger: feedbackCenter.trigger) { _, _ in
            hapticFeedbackEnabled
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            guard completed else { return }
            selectedTab = gesturaEnabled ? .gestura : .home
        }
        .onAppear {
            musicLibrary.loadSongs()
            viewModel.observeNowPlaying()
        }
    }
}

// MARK: - PREVIEW

#Preview {
    ContentView()
}
