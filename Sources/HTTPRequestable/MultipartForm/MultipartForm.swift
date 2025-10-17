//
//  MultipartForm.swift
//
//  Created by Waqar Malik on 1/15/23.
//

import CoreServices
import Foundation
import HTTPTypes
import OSLog
import UniformTypeIdentifiers

#if DEBUG
private let logger = Logger(.init(subsystem: "com.waqarmalik.HTTPRequestable", category: "MultipartForm"))
#else
private let logger = Logger(.disabled)
#endif

/// https://datatracker.ietf.org/doc/html/rfc7578
open class MultipartForm: AnyMultipartFormBodyPart {
  public static let encodingMemoryThreshold: UInt64 = 10000000

  public let boundary: String
  public var headers: [HTTPField]
  public let contentType: KeyedItem<String>
  public private(set) var bodyParts: [MultipartFormBodyPart] = []
  let fileManager: FileManager
  let streamBufferSize: Int

  public var contentLength: UInt64 {
    bodyParts.reduce(0) {
      $0 + $1.contentLength
    }
  }

  public init(fileManager: FileManager = .default, boundary: String = UUID().uuidString, streamBufferSize: Int = 1024) {
    self.fileManager = fileManager
    self.boundary = boundary
    self.contentType = KeyedItem(item: HTTPContentType.multipartForm.rawValue, parameters: ["boundary": boundary])
    self.headers = [HTTPField.contentType(contentType.encoded)]
    self.streamBufferSize = streamBufferSize
  }

  public func append(stream: InputStream, withLength length: UInt64, headers: [HTTPField]) {
    logger.trace("[IN]: \(#function)")
    let bodyPart = MultipartFormBodyPart(headers: headers, bodyStream: stream, contentLength: length)
    bodyParts.append(bodyPart)
  }

  public func append(stream: InputStream, withLength length: UInt64, name: String, fileName: String, mimeType: String) {
    logger.trace("[IN]: \(#function)")
    let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
    append(stream: stream, withLength: length, headers: headers)
  }

  public func append(data: Data, withName name: String, fileName: String? = nil, mimeType: String? = nil) {
    logger.trace("[IN]: \(#function)")
    let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
    let stream = InputStream(data: data)
    let length = UInt64(data.count)
    append(stream: stream, withLength: length, headers: headers)
  }

  public func append(fileURL: URL, withName name: String) throws {
    logger.trace("[IN]: \(#function)")
    let fileName = fileURL.lastPathComponent
    let pathExtension = fileURL.pathExtension

    if !fileName.isEmpty, !pathExtension.isEmpty {
      let mime = Self.mimeType(forPathExtension: pathExtension)
      try append(fileURL: fileURL, withName: name, fileName: fileName, mimeType: mime)
    } else {
      throw MultipartFormError.invalidFilename(fileURL)
    }
  }

  public func append(fileURL: URL, withName name: String, fileName: String, mimeType: String) throws {
    logger.trace("[IN]: \(#function)")
    let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)

    guard fileURL.isFileURL else {
      throw MultipartFormError.badURL(fileURL)
    }

    let isReachable = try fileURL.checkPromisedItemIsReachable()
    if isReachable == false {
      throw MultipartFormError.accessDenied(fileURL)
    }

    var isDirectory: ObjCBool = false
    let path = fileURL.path
    guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else {
      throw MultipartFormError.fileIsDirectory(fileURL)
    }

    let bodyContentLength = try fileManager.fileSize(atPath: path)
    guard let stream = InputStream(url: fileURL) else {
      throw MultipartFormError.streamCreation(fileURL)
    }

    append(stream: stream, withLength: bodyContentLength, headers: headers)
  }

  public func data(streamBufferSize: Int) throws -> Data {
    logger.trace("[IN]: \(#function)")
    headers.append(HTTPField(name: .contentLength, value: String(contentLength)))
    var encoded = Data()
    encoded.append(encodedHeadersData)
    encoded.append(boundary.initialBoundaryData)
    for (index, bodyPart) in bodyParts.enumerated() {
      if index > 0 {
        encoded.append(boundary.interstitialBoundaryData)
      }
      try encoded.append(bodyPart.data(streamBufferSize: streamBufferSize))
    }
    encoded.append(boundary.finalBoundaryData)
    return encoded
  }

  public func write(encodedDataTo fileURL: URL, streamBufferSize: Int) throws {
    logger.trace("[IN]: \(#function)")
    if fileManager.fileExists(atPath: fileURL.path) {
      throw MultipartFormError.fileAlreadyExists(fileURL)
    }

    if !fileURL.isFileURL {
      throw MultipartFormError.invalidFilename(fileURL)
    }

    guard let outputStream = OutputStream(url: fileURL, append: false) else {
      throw MultipartFormError.streamCreation(fileURL)
    }

    outputStream.open()
    defer {
      outputStream.close()
    }

    try boundary.initialBoundaryData.write(to: outputStream)
    for (index, bodyPart) in bodyParts.enumerated() {
      if index > 0 {
        try boundary.interstitialBoundaryData.write(to: outputStream)
      }
      try bodyPart.write(to: outputStream, streamBufferSize: streamBufferSize)
    }
    try boundary.finalBoundaryData.write(to: outputStream)
  }
}

extension MultipartForm {
  func contentHeaders(withName name: String, fileName: String? = nil, mimeType: String? = nil) -> [HTTPField] {
    logger.trace("[IN]: \(#function)")
    var disposition = KeyedItem(item: HTTPContentType.formData.rawValue, parameters: ["name": name])
    if let fileName {
      disposition["filename"] = fileName
    }

    var fields: [HTTPField] = []
    fields.append(.contentDisposition(disposition.encoded))
    if let mimeType {
      fields.append(HTTPField.contentType(mimeType + String.crlf))
    }
    return fields
  }
}

extension MultipartForm {
  static func mimeType(forPathExtension pathExtension: String) -> String {
    logger.trace("[IN]: \(#function)")
    if let id = UTType(filenameExtension: pathExtension), let contentType = id.preferredMIMEType {
      return contentType
    }
    return HTTPContentType.octetStream.rawValue
  }
}

extension MultipartForm: MutableCollection {
  public typealias Index = [MultipartFormBodyPart].Index
  public typealias Element = MultipartFormBodyPart

  public var startIndex: Index {
    bodyParts.startIndex
  }

  public var endIndex: Index {
    bodyParts.endIndex
  }

  public func index(after index: Index) -> Index {
    bodyParts.index(after: index)
  }

  public subscript(position: Index) -> Element {
    get {
      bodyParts[position]
    }
    set {
      bodyParts[position] = newValue
    }
  }
}
