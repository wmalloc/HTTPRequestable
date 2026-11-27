//
//  Data+OutputStream.swift
//
//  Created by Waqar Malik on 1/27/23
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Data {
  func write(to outputStream: OutputStream) throws {
    try Data.write(data: self, to: outputStream)
  }

  static func write(data: Data, to outputStream: OutputStream) throws {
    var buffer = [UInt8](repeating: 0, count: data.count)
    data.copyBytes(to: &buffer, count: data.count)
    try write(buffer: &buffer, to: outputStream)
  }

  static func write(buffer: inout [UInt8], to outputStream: OutputStream) throws {
    var bytesToWrite = buffer.count

    while bytesToWrite > 0 {
      let bytesWritten = outputStream.write(buffer, maxLength: bytesToWrite)
      // -1 is a failure; 0 means a fixed-length stream is full. Either way nothing more can be written.
      if bytesWritten <= 0 {
        throw MultipartFormError.outputStreamWriteFailed(outputStream.failureError)
      }
      bytesToWrite -= bytesWritten
      if bytesToWrite > 0 {
        buffer = Array(buffer[bytesWritten ..< buffer.count])
      }
    }
  }
}

extension Stream {
  /// The error to report after a read or write on this stream fails, that is, returns `-1`.
  ///
  /// On Apple platforms this is the stream's `streamError`. Foundation on Linux traps when
  /// `streamError` is read, so a generic error is reported there instead.
  var failureError: any Error {
    #if canImport(Darwin)
    if let streamError {
      return streamError
    }
    #endif
    return NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)
  }
}
