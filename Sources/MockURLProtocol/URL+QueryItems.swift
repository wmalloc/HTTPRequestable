//
//  URL+QueryItems.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/16/25.
//

import Foundation

extension URL {
  var byRemovingQueryItems: URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return self
    }
    components.queryItems = nil
    return components.url ?? self
  }
}
