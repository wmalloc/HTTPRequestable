//
//  ContentView.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import SwiftUI
import WebKit

struct ContentView: View {
  @Bindable var viewModel = SampleViewModel()

  var body: some View {
    NavigationStack {
      List(viewModel.filteredItems) { item in
        if let url = item.url {
          NavigationLink {
            ItemWebView(url: url)
          } label: {
            ListItemView(item: item)
          }
        } else {
          ListItemView(item: item)
        }
      }
      .listStyle(.plain)
      .scrollIndicators(.hidden)
      .navigationTitle(Text("Hacker News"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.visible, for: .navigationBar)
      .toolbarBackground(Color.red)
      .safeAreaInset(edge: .top, spacing: 0) {
        Picker("Story Type", selection: $viewModel.storyType) {
          ForEach(StoryType.allCases) { type in
            Text(type.title).tag(type)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
      }
      .onChange(of: viewModel.storyType) {
        viewModel.loadTopStories()
      }
      .searchable(text: $viewModel.searchText, placement: .automatic, prompt: Text("Filter by title"))
      .refreshable {
        viewModel.loadTopStories()
      }
    }
  }
}

#Preview {
  ContentView()
    .environment(SampleViewModel())
}
