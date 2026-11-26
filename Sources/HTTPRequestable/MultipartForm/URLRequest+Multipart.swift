//
//  URLRequest+Multipart.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension URLRequest {
  /// Sets the form's encoded data as the body, with its `Content-Type` (including the boundary) and
  /// `Content-Length` headers.
  ///
  /// - Parameter multipartForm: The form to send.
  /// - Returns: The modified `URLRequest` instance.
  /// - Throws: An error from reading the form's body parts.
  @discardableResult
  func setMultipartFormData(_ multipartForm: MultipartForm) throws -> Self {
    try setHttpHeader(multipartForm.contentType.encoded, forField: .contentType)
      .setHttpBody(multipartForm.data(streamBufferSize: multipartForm.streamBufferSize))
  }
}
