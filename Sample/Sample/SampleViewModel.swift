//
//  SampleViewModel.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import OSLog
import SwiftUI

@MainActor @Observable
class SampleViewModel {
  var items: [Item] = []

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
    let items = try await HackerNews.shared.topStories()

    withAnimation {
      self.items = items
    }
  }
}
