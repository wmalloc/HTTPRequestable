//
//  OperatingSystemVersion+Version.swift
//
//  Created by Waqar Malik on 4/28/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public extension OperatingSystemVersion {
  var url_versionString: String {
    "\(majorVersion).\(minorVersion).\(patchVersion)"
  }
}
