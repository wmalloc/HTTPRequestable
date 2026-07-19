//
//  ProcessInfo+AppName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif

public extension ProcessInfo {
  var url_appName: String? {
    arguments.first?.split(separator: "/").last.map(String.init)
  }
}
