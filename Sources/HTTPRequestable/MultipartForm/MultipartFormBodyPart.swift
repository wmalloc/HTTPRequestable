//
//  MultipartFormBodyPart.swift
//
//  Created by Waqar Malik on 1/24/23
//

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif
import HTTPTypes

/// Represents a single multipart/form-data body part.
///
/// A body part consists of encoded headers followed by a byte stream for the body.
/// The `headers` are expected to be encoded according to RFC 7578 with CRLF line endings
/// and a blank line separating headers from the body (i.e., `\r\n\r\n`).
///
/// Note: `bodyStream` is consumed when `data(streamBufferSize:)` or `write(to:streamBufferSize:)` is called.
/// A single instance should not be read multiple times unless the underlying stream can be rewound
/// or recreated.
open class MultipartFormBodyPart: AnyMultipartFormBodyPart {
  public let headers: [HTTPField]
  public let bodyStream: InputStream
  public let contentLength: UInt64

  public init(headers: [HTTPField], bodyStream: InputStream, contentLength: UInt64) {
    self.headers = headers
    self.bodyStream = bodyStream
    self.contentLength = contentLength
  }
}

public extension MultipartFormBodyPart {
  /// Encodes headers and body into a single `Data` value.
  ///
  /// This method reads the entire `bodyStream` into memory using `streamBufferSize` chunks and
  /// validates that the total number of bytes read matches `contentLength`.
  func data(streamBufferSize: Int) throws -> Data {
    var encoded = Data()
    encoded.append(encodedHeadersData)
    let bodyStreamData = try encodedBodyStream(streamBufferSize: streamBufferSize)
    encoded.append(bodyStreamData)
    return encoded
  }
}

extension MultipartFormBodyPart {
  private func encodedBodyStream(streamBufferSize: Int) throws -> Data {
    let inputStream = bodyStream
    inputStream.open()
    defer {
      inputStream.close()
    }

    var encoded = Data()

    while inputStream.hasBytesAvailable {
      var buffer = [UInt8](repeating: 0, count: streamBufferSize)
      let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

      if let error = inputStream.streamError {
        throw MultipartFormError.inputStreamReadFailed(error)
      }

      if bytesRead > 0 {
        encoded.append(buffer, count: bytesRead)
      } else {
        break
      }
    }

    guard UInt64(encoded.count) == contentLength else {
      let message = String(localized: "multipart_error_expected_length", bundle: .module) + " \(contentLength), " +
        String(localized: "multipart_error_encoded_length", bundle: .module) + " \(encoded.count)"
      throw MultipartFormError.inputStreamLength(message)
    }

    return encoded
  }
}

extension MultipartFormBodyPart {
  /// Streams the encoded headers and body to the provided `OutputStream`.
  ///
  /// This method does not buffer the entire body in memory and validates the number of bytes
  /// read from `bodyStream` against `contentLength`.
  func write(to outputStream: OutputStream, streamBufferSize: Int) throws {
    let headerData = encodedHeadersData
    try Data.write(data: headerData, to: outputStream)
    try write(bodyStreamTo: outputStream, streamBufferSize: streamBufferSize)
  }

  func write(bodyStreamTo outputStream: OutputStream, streamBufferSize: Int) throws {
    let inputStream = bodyStream

    inputStream.open()
    defer {
      inputStream.close()
    }
    var totalRead: UInt64 = 0

    while inputStream.hasBytesAvailable {
      var buffer = [UInt8](repeating: 0, count: streamBufferSize)
      let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

      if let error = inputStream.streamError {
        throw MultipartFormError.inputStreamReadFailed(error)
      }

      if bytesRead > 0 {
        totalRead += UInt64(bytesRead)
        if buffer.count != bytesRead {
          buffer = Array(buffer[0 ..< bytesRead])
        }
        // If an overload exists that accepts a count, prefer it to avoid reallocation.
        // Otherwise, fall back to passing the sliced buffer.
        try Data.write(buffer: &buffer, to: outputStream)
      } else {
        break
      }
    }

    if totalRead != contentLength {
      let message = String(localized: "multipart_error_expected_length", bundle: .module) + " \(contentLength), " +
        String(localized: "multipart_error_encoded_length", bundle: .module) + " \(totalRead)"
      throw MultipartFormError.inputStreamLength(message)
    }
  }
}
