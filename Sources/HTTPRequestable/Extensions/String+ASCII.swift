//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/25/24.
//

import Foundation

extension String {
  var isASCII: Bool {
    self.utf8.allSatisfy { $0 & 0x80 == 0 }
  }
}
