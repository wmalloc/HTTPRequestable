//
//  HTTPAnyResponse.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 12/14/24.
//

import Foundation
import HTTPTypes

/// Raw response from the api call
public struct HTTPAnyResponse: Hashable, Sendable {
  /// Request that was sent to the server
  public let request: HTTPRequest

  /// Response from the server
  public let response: HTTPResponse

  /// Data returned from the call can be nil if the url was returned
  public var data: Data?

  /// file url where the item was downloaded
  public var fileURL: URL?

  /// Default initalizer
  /// - Parameters:
  ///   - request: The request that was sent to server
  ///   - response: http response from the server
  ///   - data: data if url was not the response
  ///   - fileURL: fileurl if downloading the file
  public init(request: HTTPRequest, response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil) {
    self.request = request
    self.data = data
    self.fileURL = fileURL
    self.response = response
  }
}

public extension HTTPAnyResponse {
  /// If there was a server error
  @inlinable
  var error: Error? {
    response.error
  }

  /// Status code
  @inlinable
  var status: HTTPResponse.Status {
    response.status
  }

  /// if the call was successfull
  @inlinable
  var isSuccessful: Bool {
    response.status.kind == .successful
  }

  /// Validates the result for a given status code.
  /// - Returns: Self if the status code indicates success.
  @discardableResult
  func validateStatus() throws -> Self {
    if response.status.kind != .successful {
      let errorCode = URLError.Code(rawValue: response.status.code)
      throw URLError(errorCode)
    }
    return self
  }

  /// Validates the content type if acceptable content types are given.
  /// - Parameter acceptableContentTypes: Set of acceptable content types, defaults to nil.
  /// - Returns: Self if the content type is acceptable.
  @discardableResult
  func validateContentType(_ acceptableContentTypes: Set<String>? = nil) throws -> Self {
    // bypass if no content type defined
    guard let acceptableContentTypes else {
      return self
    }

    // if the server did not set the content type then throw a bad server response
    guard let contentType = response.headerFields[.contentType] else {
      throw HTTPError.contentTypeHeaderMissing
    }

    // if content type is not acceptable throw and errro
    guard acceptableContentTypes.contains(contentType) else {
      throw HTTPError.invalidContentType
    }

    // success
    return self
  }
}

public extension HTTPAnyResponse {
  func transformed<ResultType>(using transformer: Transformer<Data, ResultType>?) throws -> ResultType {
    guard let transformer else {
      throw URLError(.cannotDecodeContentData)
    }
    guard let data else {
      throw URLError(.zeroByteResource)
    }
    return try transformer(data)
  }
}
