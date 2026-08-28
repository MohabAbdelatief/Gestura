//
//  SettingsTabView.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 29/04/2026.
//

import SwiftUI

struct SettingsTabView: View {

    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var libraryStore: LibraryStore = .shared
    @ObservedObject var viewModel: PlayerViewModel
    @AppStorage(GesturaSettings.enabledKey) private var gesturaEnabled: Bool =
        GesturaSettings.enabledDefault
    @AppStorage("songSortingOption") private var songSortingOption: SortOption =
        .title
    @AppStorage(RecognizerSensitivity.appStorageKey)
    private var recognizerSensitivity: RecognizerSensitivity = .standard
    @AppStorage("detectionChimeEnabled") private var detectionChimeEnabled: Bool = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true

    // MARK: - STATE

    @State private var confirmClearFavorites: Bool = false
    @State private var confirmClearRecentlyPlayed: Bool = false

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Playback")) {
                    Picker(
                        "Default Repeat Mode",
                        selection: Binding(
                            get: { viewModel.repeatMode },
                            set: { newValue in
                                viewModel.setRepeatMode(newValue)
                            }
                        )
                    ) {
                        Text("Off").tag(RepeatMode.off)
                        Text("One").tag(RepeatMode.one)
                        Text("All").tag(RepeatMode.all)
                    }

                    Toggle(
                        "Enable Shuffle",
                        isOn: Binding(
                            get: { viewModel.isShuffleEnabled },
                            set: { newValue in
                                viewModel.setShuffleEnabled(newValue)
                            }
                        )
                    )

                }
                Section(header: Text("Gestura")) {
                    Toggle(
                        "Gesture Control",
                        isOn: $gesturaEnabled
                    )

                    Picker(
                        "Recognizer Speed",
                        selection: $recognizerSensitivity
                    ) {
                        ForEach(RecognizerSensitivity.allCases, id: \.self) {
                            sensitivity in
                            Text(sensitivity.displayName).tag(sensitivity)
                        }
                    }

                    Toggle(
                        "Detection Chime",
                        isOn: $detectionChimeEnabled
                    )

                    Toggle(
                        "Haptic Feedback",
                        isOn: $hapticFeedbackEnabled
                    )

                    NavigationLink {
                        GesturaPrivacyView()
                    } label: {
                        Label(
                            "How Gestura Uses Your Camera",
                            systemImage: "lock.shield"
                        )
                    }
                }

                Section(header: Text("Gesture Reference")) {
                    ForEach(Gesture.allCases, id: \.self) { gesture in
                        HStack {
                            Image(systemName: gesture.sfSymbolName)
                                .frame(width: 28)
                                .foregroundStyle(.tint)
                            Text(gesture.displayName)
                            Spacer()
                            Text(gesture.actionDescription)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("Library")) {
                    Button(
                        "Clear Favorites",
                        role: .destructive
                    ) {
                        confirmClearFavorites.toggle()
                    }
                    Button(
                        "Clear Recently Played",
                        role: .destructive
                    ) {
                        confirmClearRecentlyPlayed.toggle()
                    }
                }

                Section(header: Text("About")) {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?[
                            "CFBundleShortVersionString"
                        ] as? String ?? "Unknown"
                    )
                    LabeledContent(
                        "Developer",
                        value: "Mohab Abdelatief"
                    )
                }
            }
            .alert(
                "Are you sure you want to clear all favorites?",
                isPresented: $confirmClearFavorites,
            ) {
                Button("Clear", role: .destructive) {
                    libraryStore.clearFavorites()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .alert(
                "Are you sure you want to clear all recently played?",
                isPresented: $confirmClearRecentlyPlayed,
            ) {
                Button("Clear", role: .destructive) {
                    libraryStore.clearRecentlyPlayed()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .navigationTitle(
                "Settings"
            )
        }
    }
}
