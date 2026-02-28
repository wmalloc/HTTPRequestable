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
  @MainActor
  var searchText: String = ""

  @MainActor
  var filteredItems: [Item] {
    guard !searchText.isEmpty else {
      return items
    }

    return items.filter { item in
      item.title.contains(searchText)
    }
  }

  func loadTopStories() {
    Task {
      await loadStories()
    }
  }

  func loadStories() async {
    await MainActor.run {
      self.items.removeAll()
    }
    do {
      let items = try await HackerNews.shared.stories(type: "topstories")
      for item in items {
        let items = try await HackerNews.shared.item(id: item)
        await MainActor.run {
          withAnimation {
            self.items.append(items)
          }
        }
      }
    } catch {
      os_log(.error, "Unable to get stories %@", error.localizedDescription)
    }
  }
}
