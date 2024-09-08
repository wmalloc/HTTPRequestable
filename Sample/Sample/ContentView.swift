//
//  ContentView.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var viewModel: SampleViewModel

  var body: some View {
    NavigationStack {
      Section("Top Stotes") {
        List(viewModel.items) { item in
          Text(item.title)
        }
        .listStyle(.plain)
      }
      .navigationTitle("Hacker News")
      .onAppear {
        viewModel.topStories()
      }
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(SampleViewModel())
}
