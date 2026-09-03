//
//  ProcessInfo+AppName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public extension ProcessInfo {
  var url_appName: String? {
    arguments.first?.split(separator: "/").last.map(String.init)
  }
}
