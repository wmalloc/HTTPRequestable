//
//  HTTPTransportable.swift
//
//  Created by Waqar Malik on 12/24/25.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public protocol HTTPTransportable {
  /// Performs a network request and returns the raw response.
  ///
  /// This method is part of an asynchronous networking layer that sends an `HTTPRequest`
  /// (a type‑aliased wrapper around `URLRequest`) using `URLSession`.
  ///
  /// The caller can provide an optional HTTP body (`Data?`) and an optional task delegate.
  /// If a delegate is supplied, it will be used for the created `URLSessionTask`; otherwise,
  /// the default delegate of the session is used.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to send. This includes the URL, method, headers, etc.
  ///   - body: Optional raw HTTP body data that will be attached to the request.
  ///     If `nil`, no body is added.
  ///   - delegate: An optional object conforming to `URLSessionTaskDelegate`.
  ///     It is used for task‑level callbacks such as authentication challenges or progress updates.
  /// - Returns: A value of type `HTTPDataResponse`, which encapsulates the status code,
  ///   headers, and raw data returned by the server. The caller can then decode
  ///   this response into a more specific model if desired.
  /// - Throws:
  ///   - Any error thrown by `URLSession` during task creation or execution.
  ///   - Network‑level errors such as connection failures or timeouts.
  ///
  /// This method is designed to be called from an asynchronous context (`async/await`)
  /// and will automatically propagate any networking errors up the call chain.
  func performRequest(_ request: HTTPRequest, httpBody body: Data?, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse

  /// Fetches the data for a given HTTP request using an asynchronous task.
  ///
  /// This method sends the specified `HTTPRequestConfigurable` object to a server and waits for the response. The request can optionally include a
  ///  delegate that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` object representing the HTTP request. This protocol defines properties necessary to create an URLRequest.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPDataResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the fetch operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestConfigurable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPDataResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestConfigurable`, `HTTPDataResponse`, `URLSessionTaskDelegate`
  func performRequest(_ request: some HTTPRequestConfigurable, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse

  /// Uploads a file to the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestConvertible` object to a server and waits for the response, including file data. The request can
  /// optionally include a delegate that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` object representing the HTTP upload request. This protocol defines properties necessary to create an URLRequest.
  ///   - fileURL: The `URL` of the file to upload.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPDataResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the upload operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestConvertible` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPDataResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestConvertible`, `HTTPDataResponse`, `URLSessionTaskDelegate`
  func upload(for request: some HTTPRequestConvertible, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse

  /// Uploads data to the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestConfigurable` object to a server and waits for the response, including data body. The request can optionally include a delegate
  /// that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` object representing the HTTP upload request. This protocol defines properties necessary to create an URLRequest.
  ///   - multipartForm: The data body to upload as multipartform.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPDataResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the upload operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestConfigurable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPDataResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestConfigurable`, `HTTPDataResponse`, `URLSessionTaskDelegate`
  func upload(for request: some HTTPRequestConfigurable, multipartForm: MultipartForm, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse

  /// Convenience method to download using an `HTTPRequestConvertible`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse

  /// Downloads data from the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestConvertible` object to a server and waits for the response, including file data. The request can optionally include a delegate
  /// that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` object representing the HTTP download request. This protocol defines properties necessary to create an URLRequest.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPDataResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the download operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestConvertible` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPDataResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestConvertible`, `HTTPDataResponse`, `URLSessionTaskDelegate`
  func bytes(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, HTTPResponse)

  /// Sends an HTTP request and returns the parsed object of type `Request.ResultType` asynchronously.
  ///
  /// This method sends the specified `HTTPRequestConfigurable` object to a server and waits for the response. The request can optionally include a delegate
  ///  that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request. The response data is then parsed into an object of type `Request.ResultType`.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` object representing the HTTP request. This protocol defines properties necessary to create an URLRequest and also specifies the type of the resulting object `ResultType`.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An object of type `Request.ResultType` which is the parsed response from the server.
  /// - Throws: An error of type `Error` if the fetch operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestConfigurable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `ResultType` must be defined by the request object and represents the type of the resulting object after parsing.
  ///
  /// - SeeAlso: `HTTPRequestConfigurable`, `URLSessionTaskDelegate`
  func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)?) async throws -> R.ResultType
}
