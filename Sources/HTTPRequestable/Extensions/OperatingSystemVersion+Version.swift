//
//  OperatingSystemVersion+Version.swift
//
//  Created by Waqar Malik on 4/28/23.
//

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif

public extension OperatingSystemVersion {
  var url_versionString: String {
    "\(majorVersion).\(minorVersion).\(patchVersion)"
  }
}
