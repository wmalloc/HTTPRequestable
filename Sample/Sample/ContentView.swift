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
    NavigationStack {
      List(viewModel.items) { item in
        ItemDetailView(item: item)
      }
      .listStyle(.plain)
      .scrollIndicators(.hidden)
      .navigationTitle(Text("Hacker News"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.visible, for: .navigationBar)
      .refreshable {
        Task {
          viewModel.topStories()
        }
      }
      .onAppear {
        viewModel.topStories()
      }
    }
  }
}

#Preview {
  ContentView()
    .environment(SampleViewModel())
}
