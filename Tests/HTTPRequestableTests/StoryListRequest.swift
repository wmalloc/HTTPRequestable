//
//  StoryListRequest.swift
//
//  Created by Waqar Malik on 11/1/24.
//

import Foundation
import HTTPRequestable
import HTTPTypes

struct StoryListRequest: HTTPRequestConfigurable {
  typealias ResultType = [Int]

  let environment: HTTPEnvironment
  var headerFields: HTTPFields? = .init([.accept(.json)])
  var queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]
  let path: String?

  init(_ environment: HTTPEnvironment, storyType: String) throws {
    precondition(!storyType.isEmpty, "Story type cannot be empty")
    self.environment = environment
    self.path = "/\(storyType).json"
  }
}
