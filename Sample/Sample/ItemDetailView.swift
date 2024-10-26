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
    Text(item.title)
  }
}

#Preview {
  ItemDetailView(item: Item(id: 349483, by: "Turing", descendants: 0, kids: [], score: 10, time: Date(),
                            title: "New Idea for Automata", type: "story",
                            url: URL(string: "https://en.wikipedia.org/wiki/Alan_Turing")!))
}
