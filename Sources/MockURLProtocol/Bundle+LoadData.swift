//
//  Bundle+LoadData.swift
//
//
//  Created by Waqar Malik on 5/31/24.
//

import Foundation

public extension Bundle {
  func data(forResource: String, withExtension: String, subdirectory: String = "MockData") throws -> Data {
    guard let url = url(forResource: forResource, withExtension: withExtension, subdirectory: subdirectory) else {
      throw URLError(.fileDoesNotExist)
    }
    return try Data(contentsOf: url, options: [.mappedIfSafe])
  }
}
