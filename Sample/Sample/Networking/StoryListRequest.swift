//
//  StoryListRequest.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable
import HTTPTypes

struct StoryListRequest: HTTPRequestable {
  typealias ResultType = [Int]

  let environment: HTTPEnvironment
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let path: String?

  var responseTransformer: Transformer<Data, ResultType> {
    { data, _ in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }

  init(environment: HTTPEnvironment, storyType: String) throws {
    precondition(!storyType.isEmpty, "Story type cannot be empty")
    self.environment = environment
    self.path = "/\(storyType).json"
  }
}
