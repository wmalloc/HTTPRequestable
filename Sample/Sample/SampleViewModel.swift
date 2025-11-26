//
//  SampleViewModel.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import OSLog
import SwiftUI

@Observable
class SampleViewModel {
  @MainActor var items: [Item] = []

  var task: Task<Void, Error>? {
    didSet {
      oldValue?.cancel()
    }
  }

  func topStories() {
    task = Task {
      do {
        try await topStories()
      } catch {
        os_log("Unable to fetch top stories: %{public}@", log: .default, type: .error, error.localizedDescription)
      }
    }
  }

  func topStories() async throws {
    let items = try await HackerNews.shared.topStories()

    await MainActor.run {
      withAnimation {
        self.items = items
      }
    }
  }
}
