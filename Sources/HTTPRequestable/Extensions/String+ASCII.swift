//
//  String+ASCII.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/25/24.
//

import Foundation

extension String {
  /// A Boolean value indicating whether the string contains only ASCII characters.
  ///
  /// This property checks if all UTF-8 code units of the string are within the ASCII range (0x00 to 0x7F).
  var isASCII: Bool {
    utf8.allSatisfy { $0 & 0x80 == 0 }
  }
}
