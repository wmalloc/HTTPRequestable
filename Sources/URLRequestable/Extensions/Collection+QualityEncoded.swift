//
//  Collection+QualityEncoded.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

extension Collection<String> {
  func url_qualityEncoded() -> Element {
    enumerated().map { index, encoding in
      let quality = 1.0 - (Double(index) * 0.1)
      return "\(encoding);q=\(quality)"
    }.joined(separator: ", ")
  }
}
