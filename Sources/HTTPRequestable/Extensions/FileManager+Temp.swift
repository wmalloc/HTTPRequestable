//
//  FileManager+Temp.swift
//
//  Created by Waqar Malik on 12/24/25.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

extension FileManager {
  func tempFile() throws -> URL {
    let directoryURL = temporaryDirectory.appendingPathComponent("com.waqarmalik.HTTPTransferable/multipart.form.data")
    let fileName = UUID().uuidString
    let fileURL = directoryURL.appendingPathComponent(fileName)
    try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    return fileURL
  }
}
