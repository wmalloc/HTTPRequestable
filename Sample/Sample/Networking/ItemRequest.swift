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

  var responseDataTransformer: Transformer<Data, ResultType>? {
    Self.jsonDecoder
  }

  init(environment: HTTPEnvironment, item: Int) throws {
    self.environment = environment
    self.path = "/item/\(item).json"
  }
}
