//
//  Data+Validation.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public extension Data {
  /**
   Checks if the data is empty or not, throws if data is empty

   - returns: Data
   */
  @discardableResult
  func url_validateNotEmptyData() throws -> Self {
    guard !isEmpty else {
      throw URLError(.zeroByteResource)
    }
    return self
  }
}

public extension Data? {
  /// validate the Data is not empty
  /// - Returns: Data
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
