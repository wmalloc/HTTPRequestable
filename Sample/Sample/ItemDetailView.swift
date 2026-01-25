//
//  ItemDetailView.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import SwiftUI

struct ItemDetailView: View {
  let item: Item

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(item.title)
        .font(.body)
      Text("\(item.score) points by \(item.by)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  ItemDetailView(item: Item(id: 349483, by: "Turing", descendants: 0, kids: [], score: 10, time: Date(),
                            title: "New Idea for Automata", type: "story",
                            url: URL(string: "https://en.wikipedia.org/wiki/Alan_Turing")!))
}
