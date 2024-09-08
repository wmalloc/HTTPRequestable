//
//  ItemRequest.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable
import HTTPTypes

struct ItemRequest: HTTPRequestable {
  typealias ResultType = Item

  let environment: HTTPEnvironment
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let path: String?

  var responseTransformer: Transformer<Data, ResultType> {
    { data, _ in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }

  init(environment: HTTPEnvironment, item: Int) throws {
    self.environment = environment
    self.path = "/item/\(item).json"
  }
}
