//
//  KeyedItem.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation

public struct KeyedItem<ItemType: Codable & Equatable & Sendable>: Equatable, Sendable {
  public let item: ItemType
  public var parameters: [String: String]

  public init(item: ItemType, parameters: [String: String]) {
    self.item = item
    self.parameters = parameters
  }

  subscript(key: String) -> String? {
    get { parameters[key] }
    set { parameters[key] = newValue }
  }

  var encoded: String {
    "\(item); " + parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
  }
}

extension KeyedItem: Collection {
  public var startIndex: Dictionary<String, String>.Index {
    parameters.startIndex
  }

  public var endIndex: Dictionary<String, String>.Index {
    parameters.endIndex
  }

  public func index(after i: Dictionary<String, String>.Index) -> Dictionary<String, String>.Index {
    parameters.index(after: i)
  }

  public subscript(position: Dictionary<String, String>.Index) -> Dictionary<String, String>.Element {
    parameters[position]
  }
}

extension KeyedItem: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
