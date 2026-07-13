//
//  FeedbackCenter.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 13/05/2026.
//

import Combine
import Foundation

@MainActor
final class FeedbackCenter: ObservableObject {
    // MARK: - PUBLISHED PROPERTIES

    @Published var message: String?
    @Published var trigger: Int = 0

    // MARK: - PROPERTIES

    private var dismissTask: Task<Void, Never>?

    // MARK: - FUNCTIONS

    func show(_ message: String) {
        dismissTask?.cancel()
        self.message = message
        trigger += 1

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self.message = nil
        }
    }

    // MARK: - DEINIT

    deinit {
        dismissTask?.cancel()
    }
}
