//
//  HTTPField+ContentDisposition.swift
//
//
//  Created by Waqar Malik on 5/24/24.
//

import Foundation
import HTTPTypes

public extension HTTPField {
  static func contentDisposition(_ value: Quality) -> Self {
    .init(name: .contentDisposition, value: value.encoded)
  }
}
