//
//  StreamFailureTests.swift
//
//  Created by Waqar Malik on 11/26/26.
//

import Foundation
@testable import HTTPRequestable
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An input stream whose reads fail.
private final class FailingInputStream: InputStream {
  private var isOpen = false

  init() {
    super.init(data: Data())
  }

  override func open() {
    isOpen = true
  }

  override func close() {
    isOpen = false
  }

  override var hasBytesAvailable: Bool {
    isOpen
  }

  override var streamStatus: Stream.Status {
    isOpen ? .error : .notOpen
  }

  override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
    -1
  }

  #if canImport(Darwin)
  override var streamError: (any Error)? {
    NSError(domain: "StreamFailureTests", code: 7)
  }
  #endif
}

/// An output stream whose writes fail.
private final class FailingOutputStream: OutputStream {
  // Foundation on Linux declares init(toMemory:) `required`; on Apple platforms it is a plain override.
  #if canImport(Darwin)
  override init(toMemory: ()) {
    super.init(toMemory: ())
  }
  #else
  required init(toMemory: ()) {
    super.init(toMemory: ())
  }
  #endif

  override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
    -1
  }

  #if canImport(Darwin)
  override var streamError: (any Error)? {
    NSError(domain: "StreamFailureTests", code: 8)
  }
  #endif
}

/// The underlying error of `error`, when it is one of the stream failures.
private func underlyingError(_ error: MultipartFormError?) -> NSError? {
  switch error {
  case .inputStreamReadFailed(let underlying)?, .outputStreamWriteFailed(let underlying)?:
    underlying as NSError
  default:
    nil
  }
}

struct StreamFailureTests {
  @Test("A failed read is reported as inputStreamReadFailed")
  func readFailure() {
    let form = MultipartForm(boundary: "B")
    form.append(stream: FailingInputStream(), withLength: 4, headers: [])
    let error = #expect(throws: MultipartFormError.self) {
      try form.data(streamBufferSize: 16)
    }
    let underlying = underlyingError(error)
    #expect(underlying != nil)
    #if canImport(Darwin)
    #expect(underlying?.code == 7)
    #endif
  }

  @Test("A failed write is reported as outputStreamWriteFailed")
  func writeFailure() {
    var buffer: [UInt8] = [1, 2, 3]
    let error = #expect(throws: MultipartFormError.self) {
      try Data.write(buffer: &buffer, to: FailingOutputStream(toMemory: ()))
    }
    let underlying = underlyingError(error)
    #expect(underlying != nil)
    #if canImport(Darwin)
    #expect(underlying?.code == 8)
    #endif
  }

  @Test("Streams that do not fail are read and written in full")
  func noFailure() throws {
    let form = MultipartForm(boundary: "B")
    form.append(stream: InputStream(data: Data("abcd".utf8)), withLength: 4, headers: [])
    let data = try form.data(streamBufferSize: 2)
    #expect(String(decoding: data, as: UTF8.self).contains("abcd"))

    let output = OutputStream(toMemory: ())
    output.open()
    var buffer: [UInt8] = Array("xyz".utf8)
    try Data.write(buffer: &buffer, to: output)
    let written = output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
    #expect(written == Data("xyz".utf8))
  }
}
