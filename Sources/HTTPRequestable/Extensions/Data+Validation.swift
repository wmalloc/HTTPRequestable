//
//  Data+Validation.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

/// Extension providing validation methods for Data instances.
public extension Data {
  /// Validates that the data is not empty. If the data is empty, it throws a URLError with code `.zeroByteResource`.
  /// - Returns: The `Data` instance if it is not empty.
  @discardableResult
  func url_validateNotEmptyData() throws -> Self {
    guard !isEmpty else {
      throw URLError(.zeroByteResource)
    }
    return self
  }
}

/// Extension providing validation methods for optional Data instances.
public extension Data? {
  /// Validates that the data is not empty. If the data is nil or empty, it throws a URLError with the appropriate code:
  /// - `.cannotDecodeContentData` if the data itself is nil.
  /// - `.zeroByteResource` if the data exists but is empty.
  /// - Returns: The non-nil and non-empty `Data` instance.
  @discardableResult
  func url_validateNotEmptyData() throws -> Self {
    guard let data = self else {
      throw URLError(.cannotDecodeContentData)
    }
    guard !data.isEmpty else {
      throw URLError(.zeroByteResource)
    }
    return data
  }
}
