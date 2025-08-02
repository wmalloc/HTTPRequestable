//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 7/30/25.
//

import Foundation

public typealias AsyncArray<Element> = Array<Element>

extension AsyncArray: AsyncSequence {
  public struct AsyncIterator: AsyncIteratorProtocol {
    let elements: [Element]
    var index = 0

    public init(elements: [Element]) {
      self.elements = elements
    }

    mutating public func next() -> Element? {
      guard !Task.isCancelled else { return nil }
      guard index < elements.count else { return nil }
      defer { index += 1 }
      return elements[index]
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(elements: self)
  }
}
