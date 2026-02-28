//
//  ContentView.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import SwiftUI

struct ContentView: View {
  @Environment(SampleViewModel.self) var viewModel: SampleViewModel

  var body: some View {
    @Bindable var model = viewModel

    NavigationStack {
      List(viewModel.filteredItems) { item in
        ItemDetailView(item: item)
      }
      .listStyle(.plain)
      .scrollIndicators(.hidden)
      .navigationTitle(Text("Hacker News"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.visible, for: .navigationBar)
      .searchable(text: $model.searchText, placement: .automatic, prompt: Text("Filter by title"))
      .refreshable {
        viewModel.loadTopStories()
      }
      .onAppear {
        viewModel.loadTopStories()
      }
    }
  }
}

#Preview {
  ContentView()
    .environment(SampleViewModel())
}
