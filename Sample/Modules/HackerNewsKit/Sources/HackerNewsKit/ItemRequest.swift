//
//  ItemRequest.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable

@Endpoint(headerFields: [.accept: HTTPContentType.json.rawValue])
struct ItemRequest: HTTPRequestConfigurable {
  typealias ResultType = Item

  let environment: HTTPEnvironment
  let path: String

  init(_ environment: HTTPEnvironment, item: Int) throws {
    self.environment = environment
    self.path = "/item/\(item).json"
  }
}
