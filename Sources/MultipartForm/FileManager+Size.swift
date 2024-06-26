//
//  FileManager+Size.swift
//
//  Created by Waqar Malik on 1/21/23
//

import Foundation

extension FileManager {
  func fileSize(atPath path: String) throws -> UInt64 {
    guard let fileSize = try attributesOfItem(atPath: path)[.size] as? NSNumber else {
      throw MultipartFormError.fileSizeNotAvailable(URL(fileURLWithPath: path))
    }
    return fileSize.uint64Value
  }
}
