//
//  SampleViewModel.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import OSLog

@MainActor @Observable
class SampleViewModel {
  var items: [Item] = []

  let hackerNews = HackerNews()

  func topStories() {
    Task {
      do {
        try await topStories()
      } catch {
        os_log("Unable to fetch top stories: %{public}@", log: .default, type: .error, error.localizedDescription)
      }
    }
  }

  func topStories() async throws {
    let items = try await hackerNews.topStories()
    self.items = items
  }
}
