//
//  String+ASCII.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/25/24.
//

import Foundation

extension String {
  var isASCII: Bool {
    utf8.allSatisfy { $0 & 0x80 == 0 }
  }
}
