//
//  String+OSName.swift
//
//  Created by Waqar Malik on 4/28/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
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
    #else
    "Unknown"
    #endif
  }
}
