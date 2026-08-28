//
//  SampleViewModel.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HackerNewsKit
import OSLog
import SwiftUI

@Observable
class SampleViewModel {
  @MainActor var items: [Item] = []
  @MainActor var searchText: String = ""
  @MainActor var storyType: StoryType = .top
  @MainActor private var loadingTask: Task<Void, Never>?

  init() {
    Task { @MainActor [self] in
      loadTopStories()
    }
  }

  @MainActor
  var filteredItems: [Item] {
    guard !searchText.isEmpty else {
      return items
    }

    return items.filter { item in
      item.title.contains(searchText)
    }
  }

  @MainActor
  func loadTopStories() {
    loadingTask?.cancel()
    loadingTask = Task {
      await loadStories()
    }
  }

  func loadStories() async {
    let selectedType = await MainActor.run { self.storyType }
    await MainActor.run {
      self.items.removeAll()
    }
    do {
      let ids = try await HackerNews.shared.stories(type: selectedType.rawValue)
      for id in ids {
        try Task.checkCancellation()
        let item = try await HackerNews.shared.item(id: id)
        await MainActor.run {
          withAnimation {
            self.items.append(item)
          }
        }
      }
    } catch is CancellationError {
      // Task was cancelled by a new selection; nothing to do
    } catch {
      os_log(.error, "Unable to get stories %@", error.localizedDescription)
    }
  }
}
