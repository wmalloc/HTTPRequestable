//
//  URLRequest+Multipart.swift
//
//  Created by Waqar Malik on 1/14/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public extension URLRequest {
  /// Append the multipart form data to request, and header fields
  @discardableResult
  func setMultipartFormData(_ multipartForm: MultipartForm) throws -> Self {
    try setHttpBody(multipartForm.data(streamBufferSize: multipartForm.streamBufferSize), contentType: multipartForm.contentType.encoded)
  }
}
