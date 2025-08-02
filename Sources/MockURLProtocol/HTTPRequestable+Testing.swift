//
//  HTTPRequestable+Testing.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPRequestable

public extension HTTPRequestable {
  func addTestIdentifierHeader() -> Self {
    var request = self
    var existing = request.headerFields ?? [:]
    existing[.testIdentifier] = UUID().uuidString
    request.headerFields = existing
    return request
  }

  var testIdentifier: String? {
    headerFields?[.testIdentifier]
  }
}

extension URLRequest {
  var testIdentifier: String? {
    value(forHTTPField: .testIdentifier)
  }
}
