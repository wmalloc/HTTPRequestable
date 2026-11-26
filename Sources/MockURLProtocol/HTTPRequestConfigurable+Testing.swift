//
//  HTTPRequestConfigurable+Testing.swift
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPRequestable
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension HTTPRequestConfigurable {
  /// A copy of the request with an `X-Mock-Identifier` header set to a random UUID.
  ///
  /// The header gives the request an identifier of its own, so ``MockURLProtocol`` can answer it with
  /// its own handler even when other requests share its URL. Other headers are kept; an existing
  /// `X-Mock-Identifier` header is replaced.
  ///
  /// ```swift
  /// let request = try StoryListRequest(environment, storyType: "topstories").byAddingMockIdentifierHeader()
  /// try await MockURLProtocol.setRequestHandler(handler, forRequest: request)
  /// ```
  ///
  /// - Returns: A copy of the request with the header set.
  func byAddingMockIdentifierHeader() -> Self {
    var request = self
    request.headerFields[.xMockIdentifier] = UUID().uuidString
    return request
  }

  /// The value of the `X-Mock-Identifier` header, or `nil` when it is not set.
  var mockIdentifier: String? {
    headerFields[.xMockIdentifier]
  }
}
