//
//  URL+QueryItems.swift
//
//  Created by Waqar Malik on 5/28/20.
//

import Foundation

public extension URL {
  func appendQueryItems(_ newItems: [URLQueryItem]) -> Self {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    components = components?.appendQueryItems(newItems)
    return components?.url ?? self
  }
}
