//
//  ItemWebView.swift
//
//  Created by Waqar Malik on 4/15/26.
//

import SwiftUI
import WebKit

struct ItemWebView: View {
  @State private var page = WebPage()
  let url: URL

  init(url: URL) {
    self.url = url
  }

  var body: some View {
    ZStack {
      WebView(page)
      if page.isLoading {
        VStack {
          ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.large)
            .padding(50.0)
            .tint(Color.primary)
        }
        .background(Color.primary.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 15.0, style: .continuous))
      }
    }
    .onAppear {
      let request = URLRequest(url: url)
      page.load(request)
    }
    .navigationTitle(page.title)
    .toolbarBackground(Color.red)
  }
}

#Preview {
  ItemWebView(url: URL(string: "https://www.apple.com")!)
}
