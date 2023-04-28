//
//  OperatingSystemVersion+Version.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

public extension OperatingSystemVersion {
    var url_versionString: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}
