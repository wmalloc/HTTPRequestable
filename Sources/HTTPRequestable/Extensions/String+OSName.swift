//
//  String+OSName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

extension String {
  static var url_osName: String {
    #if targetEnvironment(simulator)
    return "iOS(Simulator)"
    #elseif os(iOS)
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
    #elseif os(visionOS)
    return "visionOS"
    #else
    return "Unknown"
    #endif
  }
}
