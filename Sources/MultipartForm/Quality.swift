//
//  Quality.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation

// "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
public struct Quality: Hashable, Sendable {
  public var items: [Item]

  public init(_ items: [Item]) {
    self.items = items
  }

  public struct Item: Codable, Hashable, Sendable {
    public let item: String
    public let parameters: Parameter

    public init(item: String, parameters: Parameter) {
      self.item = item
      self.parameters = parameters
    }
  }

  public struct Parameter: Codable, Hashable, Sendable {
    public let q: Float?

    public init(q: Float? = nil) {
      self.q = q
    }
  }

  var encoded: String {
    items.map { item in
      var string = item.item
      if let q = item.parameters.q {
        string += ";q=\(q)"
      }
      return string
    }
    .joined(separator: ",")
  }
}

extension Quality: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Item...) {
    self.init(elements)
  }
}

extension Quality: MutableCollection {
  public var startIndex: Int {
    items.startIndex
  }

  public var endIndex: Int {
    items.endIndex
  }

  public func index(after i: Int) -> Int {
    items.index(after: i)
  }

  public subscript(position: Int) -> Item {
    get { items[position] }
    set { items[position] = newValue }
  }
}

extension Quality.Parameter: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Float) {
    self.init(q: value)
  }
}

extension Quality.Parameter: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self.init(q: nil)
  }
}

extension Quality.Parameter: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(q: Float(value))
  }
}

extension Quality: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
