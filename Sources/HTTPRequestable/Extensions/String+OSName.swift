//
//  String+OSName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension String {
  static var url_osName: String {
    #if targetEnvironment(simulator)
    "iOS(Simulator)"
    #elseif os(iOS)
    #if targetEnvironment(macCatalyst)
    "macOS(Catalyst)"
    #else
    "iOS"
    #endif
    #elseif os(watchOS)
    "watchOS"
    #elseif os(tvOS)
    "tvOS"
    #elseif os(macOS)
    "macOS"
    #elseif os(visionOS)
    "visionOS"
    #elseif os(Android)
    "Android"
    #elseif os(Linux)
    "Linux"
    #elseif os(Windows)
    "Windows"
    #else
    "Unknown"
    #endif
  }
}
