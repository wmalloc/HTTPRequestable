//
//  String+UserAgent.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

public extension String {
  static var url_userAgent: String {
    let infoDictionary = Bundle.main.infoDictionary
    let appName = infoDictionary?["CFBundleExecutable"] as? String ?? ProcessInfo.processInfo.url_appName ?? "Unknown App"
    let bundle = Bundle.main.bundleIdentifier ?? "Unknown-Bundle"
    let appVersion = infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown-AppVersion"
    let appBuild = infoDictionary?["CFBundleVersion"] as? String ?? "Unknown-Build"
    let os = String.url_osName + " " + ProcessInfo.processInfo.operatingSystemVersionString
    let package = "URLRequestable"
    return "\(appName)/\(appVersion) (\(bundle); build:\(appBuild); \(os)) \(package)"
  }
}
