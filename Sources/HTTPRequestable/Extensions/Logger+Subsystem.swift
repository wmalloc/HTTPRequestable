//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/4/24.
//

import Foundation
import OSLog

extension OSLog {
  @inlinable
  static var subsystem: String { "com.waqarmalik.HTTPRequestable" }
  
  @inlinable
  convenience init(category: String) {
    self.init(subsystem: Self.subsystem, category: category)
  }
}

extension Logger {
  @inlinable
  static var subsystem: String { OSLog.subsystem }
  
  @inlinable
  init(category: String) {
    self.init(subsystem: Self.subsystem, category: category)
  }
}
