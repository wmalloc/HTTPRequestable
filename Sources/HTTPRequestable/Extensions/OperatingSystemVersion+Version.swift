//
//  OperatingSystemVersion+Version.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension OperatingSystemVersion {
  var url_versionString: String {
    "\(majorVersion).\(minorVersion).\(patchVersion)"
  }
}
