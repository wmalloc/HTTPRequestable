//
//  ItemRequest.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable
import HTTPTypes

struct ItemRequest: HTTPRequestConfigurable {
  typealias ResultType = Item

  let environment: HTTPEnvironment
  var headerFields: HTTPFields? = .init([.accept(.json)])
  var queryItems: [URLQueryItem]?
  let path: String?

  init(environment: HTTPEnvironment, item: Int) throws {
    self.environment = environment
    self.path = "/item/\(item).json"
  }
}
