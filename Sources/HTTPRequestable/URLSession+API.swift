//
//  URLSession+API.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation
import HTTPTypes
import OSLog

#if DEBUG
private let logger = Logger(.init(category: "URLSesion+API"))
#else
private let logger = Logger(.disabled)
#endif

public extension URLSession {
  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  func data(for request: some HTTPRequestConfigurable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try request.httpRequest
    let (data, response) = if let bodyData = request.httpBody {
      try await upload(for: updatedRequest, from: bodyData, delegate: delegate)
    } else {
      try await data(for: updatedRequest, delegate: delegate)
    }
    return HTTPAnyResponse(request: updatedRequest, response: response, data: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestConvertible, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, fromFile: fileURL, delegate: delegate)
    return HTTPAnyResponse(request: updateRequest, response: response, data: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestConvertible, from bodyData: Data, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, from: bodyData, delegate: delegate)
    return HTTPAnyResponse(request: updateRequest, response: response, data: data)
  }

  /// Convenience method to download using an `HTTPRequestConvertible`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (url, response) = try await download(for: updateRequest, delegate: delegate)
    return HTTPAnyResponse(request: updateRequest, response: response, fileURL: url)
  }

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to load data.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data stream and response.
  func bytes(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    return try await bytes(for: updateRequest, delegate: delegate)
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - request: Request where to get the data from
     - delegate: Delegate to handle the request, defaults to nil
   - returns: Transformed Object
   */
  @inlinable
  func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> R.ResultType {
    try await data(for: request, delegate: delegate)
      .transformed(using: request.responseDataTransformer)
  }
}
