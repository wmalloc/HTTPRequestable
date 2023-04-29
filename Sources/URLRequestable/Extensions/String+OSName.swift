//
//  String+OSName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

extension String {
    static var url_osName: String {
        #if os(iOS)
            #if targetEnvironment(macCatalyst)
                return "macOS(Catalyst)"
            #else
                return "iOS"
            #endif
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(macOS)
            return "macOS"
        #else
            return "Unknown"
        #endif
    }
}
