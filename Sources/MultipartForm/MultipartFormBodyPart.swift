//
//  MultipartFormBodyPart.swift
//
//  Created by Waqar Malik on 1/24/23
//

import Foundation
import HTTPTypes

open class MultipartFormBodyPart: MultipartFormBody {
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
  func encoded(streamBufferSize: Int) throws -> Data {
    var encoded = Data()
    let headerData = encodedHeaders()
    encoded.append(headerData)
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
  func write(to outputStream: OutputStream, streamBufferSize: Int) throws {
    let headerData = encodedHeaders()
    try Data.write(data: headerData, to: outputStream)
    try write(bodyStreamTo: outputStream, streamBufferSize: streamBufferSize)
  }

  func write(bodyStreamTo outputStream: OutputStream, streamBufferSize: Int) throws {
    let inputStream = bodyStream

    inputStream.open()
    defer {
      inputStream.close()
    }

    while inputStream.hasBytesAvailable {
      var buffer = [UInt8](repeating: 0, count: streamBufferSize)
      let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

      if let error = inputStream.streamError {
        throw MultipartFormError.inputStreamReadFailed(error)
      }

      if bytesRead > 0 {
        if buffer.count != bytesRead {
          buffer = Array(buffer[0 ..< bytesRead])
        }
        try Data.write(buffer: &buffer, to: outputStream)
      } else {
        break
      }
    }
  }
}
