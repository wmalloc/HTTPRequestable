//
//  SampleApp.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import SwiftUI

@main
struct SampleApp: App {
  @State private var viewModel = SampleViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(viewModel)
    }
  }
}
