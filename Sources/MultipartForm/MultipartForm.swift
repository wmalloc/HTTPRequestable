//
//  MultipartForm.swift
//
//  Created by Waqar Malik on 1/15/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import CoreServices
import Foundation
import HTTPRequestable
import HTTPTypes
import UniformTypeIdentifiers

/// https://datatracker.ietf.org/doc/html/rfc7578
open class MultipartForm: MultipartFormBody {
  public let boundary: String
  public var headers: [HTTPField]
  public let contentType: KeyedItem<String>

  public var contentLength: UInt64 {
    bodyParts.reduce(0) {
      $0 + $1.contentLength
    }
  }

  public init(fileManager: FileManager = .default, boundary: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")) {
    self.fileManager = fileManager
    self.boundary = boundary
    self.contentType = KeyedItem(item: HTTPContentType.multipartForm.rawValue, parameters: ["boundary": boundary])
    self.headers = [HTTPField.contentType(contentType.encoded)]
  }

  let fileManager: FileManager
  public private(set) var bodyParts: [MultipartFormBodyPart] = []

  public func append(stream: InputStream, withLength length: UInt64, headers: [HTTPField]) {
    let bodyPart = MultipartFormBodyPart(headers: headers, bodyStream: stream, contentLength: length)
    bodyParts.append(bodyPart)
  }

  public func append(stream: InputStream, withLength length: UInt64, name: String, fileName: String, mimeType: String) {
    let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
    append(stream: stream, withLength: length, headers: headers)
  }

  public func append(data: Data, withName name: String, fileName: String? = nil, mimeType: String? = nil) {
    let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
    let stream = InputStream(data: data)
    let length = UInt64(data.count)
    append(stream: stream, withLength: length, headers: headers)
  }

  public func append(fileURL: URL, withName name: String) throws {
    let fileName = fileURL.lastPathComponent
    let pathExtension = fileURL.pathExtension

    if !fileName.isEmpty, !pathExtension.isEmpty {
      let mime = mimeType(forPathExtension: pathExtension)
      try append(fileURL: fileURL, withName: name, fileName: fileName, mimeType: mime)
    } else {
      throw MultipartFormError.invalidFilename(fileURL)
    }
  }

  public func append(fileURL: URL, withName name: String, fileName: String, mimeType: String) throws {
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

  public func encoded(streamBufferSize: Int = 1024) throws -> Data {
    headers.append(HTTPField(name: .contentLength, value: String(contentLength)))
    var encoded = Data()
    encoded.append(encodedHeaders())
    encoded.append(initialBoundaryData)
    for (index, bodyPart) in bodyParts.enumerated() {
      if index > 0 {
        encoded.append(interstitialBoundaryData)
      }
      try encoded.append(bodyPart.encoded(streamBufferSize: streamBufferSize))
    }
    encoded.append(finalBoundaryData)
    return encoded
  }

  public func write(encodedDataTo fileURL: URL, streamBufferSize: Int) throws {
    if fileManager.fileExists(atPath: fileURL.path) {
      throw MultipartFormError.fileAlreadyExists(fileURL)
    } else if !fileURL.isFileURL {
      throw MultipartFormError.invalidFilename(fileURL)
    }

    guard let outputStream = OutputStream(url: fileURL, append: false) else {
      throw MultipartFormError.streamCreation(fileURL)
    }

    outputStream.open()
    defer {
      outputStream.close()
    }

    try initialBoundaryData.write(to: outputStream)
    for (index, bodyPart) in bodyParts.enumerated() {
      if index > 0 {
        try interstitialBoundaryData.write(to: outputStream)
      }
      try bodyPart.write(to: outputStream, streamBufferSize: streamBufferSize)
    }
    try finalBoundaryData.write(to: outputStream)
  }
}

extension MultipartForm {
  var initialBoundary: String {
    MultipartFormBoundaryType.boundary(forBoundaryType: .initial, boundary: boundary)
  }

  var initialBoundaryData: Data {
    Data(initialBoundary.utf8)
  }

  var interstitialBoundary: String {
    MultipartFormBoundaryType.boundary(forBoundaryType: .interstitial, boundary: boundary)
  }

  var interstitialBoundaryData: Data {
    Data(interstitialBoundary.utf8)
  }

  var finalBoundary: String {
    MultipartFormBoundaryType.boundary(forBoundaryType: .final, boundary: boundary)
  }

  var finalBoundaryData: Data {
    Data(finalBoundary.utf8)
  }

  func contentHeaders(withName name: String, fileName: String? = nil, mimeType: String? = nil) -> [HTTPField] {
    var disposition = KeyedItem(item: HTTPContentType.formData.rawValue, parameters: ["name": name])
    if let fileName {
      disposition["filename"] = fileName
    }

    var fields: [HTTPField] = []
    fields.append(.contentDisposition(disposition.encoded))
    if let mimeType {
      fields.append(HTTPField.contentType(mimeType + EncodingCharacters.crlf))
    }
    return fields
  }
}

extension MultipartForm {
  func mimeType(forPathExtension pathExtension: String) -> String {
    if let id = UTType(filenameExtension: pathExtension), let contentType = id.preferredMIMEType {
      return contentType
    }
    return HTTPContentType.octetStream.rawValue
  }
}

extension MultipartForm: MutableCollection {
  public var startIndex: Int {
    bodyParts.startIndex
  }

  public var endIndex: Int {
    bodyParts.endIndex
  }

  public func index(after i: Int) -> Int {
    bodyParts.index(after: i)
  }

  public subscript(position: Int) -> MultipartFormBodyPart {
    get {
      bodyParts[position]
    }
    set {
      bodyParts[position] = newValue
    }
  }
}
