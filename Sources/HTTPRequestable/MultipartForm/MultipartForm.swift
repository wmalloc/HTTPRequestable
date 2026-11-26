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

  /// Creates an empty form.
  ///
  /// - Parameters:
  ///   - fileManager: Used to read files appended by URL.
  ///   - boundary: Separates the body parts. It must be 1 to 70 characters from the set RFC 2046 allows
  ///     (letters, digits, space and `'()+_,-./:=?`) and must not end with a space. The default, a UUID,
  ///     always is.
  ///   - streamBufferSize: The size of the buffer used to copy streams into the body.
  /// - Precondition: `boundary` is valid. An invalid boundary, such as one containing CR or LF, would
  ///   be written differently in the `Content-Type` header and in the body, and the server could not
  ///   split the body.
  public init(fileManager: FileManager = .default, boundary: String = UUID().uuidString, streamBufferSize: Int = 1024) {
    precondition(Self.isValidBoundary(boundary), "MultipartForm boundary must be 1 to 70 RFC 2046 characters, not ending with a space")
    self.fileManager = fileManager
    self.boundary = boundary
    // The precondition above leaves only RFC 2046 characters, which are valid parameter values.
    self.contentType = KeyedItem(uncheckedItem: HTTPContentType.multipartForm.rawValue, parameters: ["boundary": boundary])
    self.headers = [HTTPField.contentType(contentType.encoded)]
    self.streamBufferSize = streamBufferSize
  }

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
      let mime = Self.mimeType(forPathExtension: pathExtension)
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

  public func data(streamBufferSize: Int) throws -> Data {
    var encoded = Data()
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
    var parameters = ["name": Self.quotedParameter(name)]
    if let fileName {
      parameters["filename"] = Self.quotedParameter(fileName)
    }
    // quotedParameter percent-encodes every control character, so the values are valid.
    let disposition = KeyedItem(uncheckedItem: HTTPContentType.formData.rawValue, parameters: parameters)

    var fields: [HTTPField] = []
    fields.append(.contentDisposition(disposition.encoded))
    if let mimeType {
      fields.append(HTTPField.contentType(mimeType))
    }
    return fields
  }
}

extension MultipartForm {
  /// Whether `boundary` is a valid RFC 2046 boundary: 1 to 70 `bchars`, not ending with a space.
  static func isValidBoundary(_ boundary: String) -> Bool {
    let scalars = boundary.unicodeScalars
    guard (1 ... 70).contains(scalars.count), scalars.last != " " else {
      return false
    }
    return scalars.allSatisfy { scalar in
      switch scalar {
      case "a" ... "z", "A" ... "Z", "0" ... "9", "'", "(", ")", "+", "_", ",", "-", ".", "/", ":", "=", "?", " ":
        true
      default:
        false
      }
    }
  }
}

extension MultipartForm {
  /// Returns `value` as a quoted `Content-Disposition` parameter value that cannot end the value early
  /// or inject other parameters or headers.
  ///
  /// `"` and control characters such as CR and LF are percent-encoded (RFC 7578 section 4.2). A value
  /// that the caller already wrapped in double quotes is unwrapped first, so it is not quoted twice.
  static func quotedParameter(_ value: String) -> String {
    var inner = Substring(value)
    if inner.count >= 2, inner.hasPrefix("\""), inner.hasSuffix("\"") {
      inner = inner.dropFirst().dropLast()
    }
    var escaped = ""
    for scalar in inner.unicodeScalars {
      if scalar == "\"" || HTTPFieldValueSyntax.isControlCharacter(scalar) {
        let hex = String(scalar.value, radix: 16, uppercase: true)
        escaped += (hex.count < 2 ? "%0" : "%") + hex
      } else {
        escaped.unicodeScalars.append(scalar)
      }
    }
    return "\"\(escaped)\""
  }
}

extension MultipartForm {
  static func mimeType(forPathExtension pathExtension: String) -> String {
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
