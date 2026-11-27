//
//  FileManager+Temp.swift
//
//  Created by Waqar Malik on 12/24/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension FileManager {
  func tempFile() throws -> URL {
    let directoryURL = temporaryDirectory.appendingPathComponent("com.waqarmalik.HTTPTransferable/multipart.form.data")
    let fileName = UUID().uuidString
    let fileURL = directoryURL.appendingPathComponent(fileName)
    // Owner-only, so other users cannot read multipart bodies written to disk.
    let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o700]
    try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: attributes)
    try setAttributes(attributes, ofItemAtPath: directoryURL.path)
    removeStaleTempFiles(in: directoryURL)
    return fileURL
  }
}

extension FileManager {
  /// Removes files left behind by uploads that were interrupted, for example by a crash.
  private func removeStaleTempFiles(in directoryURL: URL, olderThan age: TimeInterval = 24 * 60 * 60) {
    let cutoff = Date(timeIntervalSinceNow: -age)
    guard let urls = try? contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
      return
    }
    for url in urls {
      if let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, modified < cutoff {
        try? removeItem(at: url)
      }
    }
  }
}
