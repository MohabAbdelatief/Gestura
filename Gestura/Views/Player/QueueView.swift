//
//  QueueView.swift
//  Gestura
//

import SwiftUI

struct QueueView: View {
    // MARK: - PROPERTY WRAPPED OBJECTS

    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - VIEW

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.queue.isEmpty {
                    ContentUnavailableView(
                        "Queue Empty",
                        systemImage: "list.bullet",
                        description: Text("Tap a song to start playing.")
                    )
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(viewModel.queue.indices, id: \.self) {
                                index in
                                queueRow(at: index)
                            }
                            .onMove { source, destination in
                                viewModel.moveQueueItems(
                                    from: source,
                                    to: destination
                                )
                            }
                            .onDelete { offsets in
                                viewModel.removeQueueItem(at: offsets)
                            }
                        }
                        .onChange(of: viewModel.queueIndex) {
                            withAnimation {
                                proxy.scrollTo(
                                    viewModel.queueIndex,
                                    anchor: .center
                                )
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(
                                viewModel.queueIndex,
                                anchor: .center
                            )
                        }

                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Up Next")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    // MARK: - HELPER VIEWS

    private func queueRow(at index: Int) -> some View {
        Button {
            viewModel.jumpTo(index)
            dismiss()
        } label: {
            SongRowView(
                track: viewModel.queue[index],
                viewModel: viewModel
            )
            .opacity(
                index < viewModel.queueIndex ? 0.4 : 1.0
            )
        }
        .buttonStyle(.plain)
    }
}
