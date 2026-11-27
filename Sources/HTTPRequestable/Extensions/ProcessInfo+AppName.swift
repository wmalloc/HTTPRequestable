//
//  ProcessInfo+AppName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ProcessInfo {
  var url_appName: String? {
    arguments.first?.split(separator: "/").last.map(String.init)
  }
}
