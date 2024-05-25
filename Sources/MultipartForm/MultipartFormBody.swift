//
//  MultipartFormBody.swift
//
//
//  Created by Waqar Malik on 5/24/24.
//

import Foundation
import HTTPTypes

public protocol MultipartFormBody {
  var headers: HTTPFields { get }
  var contentLength: UInt64 { get }

  func encodedHeaders() -> Data
  func encoded(streamBufferSize: Int) throws -> Data
}

public extension MultipartFormBody {
  func encodedHeaders() -> Data {
    let headerText = headers.headerFields.map { name, value in
      "\(name): \(value)\(EncodingCharacters.crlf)"
    }
    .joined()
    + EncodingCharacters.crlf
    return Data(headerText.utf8)
  }
}
