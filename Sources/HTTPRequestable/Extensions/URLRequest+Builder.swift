//
//  URLRequest+Builder.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation
import HTTPTypes

/* 
 # URLRequest+Builder

 This extension provides a fluent interface for configuring `URLRequest` instances.
 It includes methods for setting various properties, such as HTTP headers, body, and network options.
 */

public extension URLRequest {
  /// Sets the cache policy of the `URLRequest`.
  ///
  /// - Parameter cachePolicy: The cache policy to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setCachePolicy(_ cachePolicy: URLRequest.CachePolicy) -> Self {
    var request = self
    request.cachePolicy = cachePolicy
    return request
  }

  /// Sets the HTTP method of the `URLRequest`.
  ///
  /// - Parameter httpMethod: The HTTP method to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpMethod(_ httpMethod: String?) -> Self {
    var request = self
    request.httpMethod = httpMethod
    return request
  }

  /// Sets the URL of the `URLRequest`.
  ///
  /// - Parameter url: The URL to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setUrl(_ url: URL?) -> Self {
    var request = self
    request.url = url
    return request
  }

  /// Sets the main document URL of the `URLRequest`.
  ///
  /// - Parameter maindocumentURL: The main document URL to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setMaindocumentURL(_ maindocumentURL: URL?) -> Self {
    var request = self
    request.mainDocumentURL = maindocumentURL
    return request
  }

  /// Sets the HTTP body of the `URLRequest` and optionally the `Content-Type` header.
  ///
  /// - Parameters:
  ///   - httpBody: The HTTP body data to set.
  ///   - contentType: The `Content-Type` header value to set. Defaults to `nil`.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpBody(_ httpBody: Data?, contentType: String? = nil) -> Self {
    var request = self
    if let contentType {
      request.setValue(contentType, forHTTPField: .contentType)
    }
    request.httpBody = httpBody
    if httpBody != nil {
      request.setValue("\(httpBody?.count ?? 0)", forHTTPField: .contentLength)
    }
    return request
  }

  /// Sets the HTTP body stream of the `URLRequest`.
  ///
  /// - Parameter httpBodyStream: The HTTP body stream to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpBodyStream(_ httpBodyStream: InputStream?) -> Self {
    var request = self
    request.httpBodyStream = httpBodyStream
    return request
  }

  /// Sets the timeout interval of the `URLRequest`.
  ///
  /// - Parameter timeoutInterval: The timeout interval to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setTimeoutInterval(_ timeoutInterval: TimeInterval) -> Self {
    var request = self
    request.timeoutInterval = timeoutInterval
    return request
  }

  /// Sets an HTTP header field with the specified name and value.
  ///
  /// - Parameters:
  ///   - value: The value to set for the header field.
  ///   - name: The name of the header field.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpHeader(_ value: String?, forName name: String) -> Self {
    var request = self
    request.setValue(value, forHTTPHeaderField: name)
    return request
  }

  /// Sets an HTTP header field with the specified `HTTPField.Name` and value.
  ///
  /// - Parameters:
  ///   - value: The value to set for the header field.
  ///   - name: The `HTTPField.Name` of the header field.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpHeader(_ value: String?, forField name: HTTPField.Name) -> Self {
    var request = self
    request.setValue(value, forHTTPField: name)
    return request
  }

  /// Sets multiple HTTP header fields.
  ///
  /// - Parameter httpHeaders: A dictionary of header fields and their values.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpHeaders(_ httpHeaders: [String: String]) -> Self {
    var request = self
    request.allHTTPHeaderFields = httpHeaders
    return request
  }

  /// Adds a value to an HTTP header field with the specified name.
  ///
  /// - Parameters:
  ///   - value: The value to add to the header field.
  ///   - name: The name of the header field.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func addHttpHeader(_ value: String, forName name: String) -> Self {
    var request = self
    request.addValue(value, forHTTPHeaderField: name)
    return request
  }

  /// Adds a value to an HTTP header field with the specified `HTTPField.Name`.
  ///
  /// - Parameters:
  ///   - value: The value to add to the header field.
  ///   - name: The `HTTPField.Name` of the header field.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func addHttpHeader(_ value: String, forField name: HTTPField.Name) -> Self {
    var request = self
    request.addValue(value, forHTTPField: name)
    return request
  }

  /// Sets whether the `URLRequest` should handle cookies.
  ///
  /// - Parameter httpShouldHandleCookies: A Boolean value indicating whether cookies should be handled.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpShouldHandleCookies(_ httpShouldHandleCookies: Bool) -> Self {
    var request = self
    request.httpShouldHandleCookies = httpShouldHandleCookies
    return request
  }

  /// Sets whether the `URLRequest` should use pipelining.
  ///
  /// - Parameter httpShouldUsePipelining: A Boolean value indicating whether pipelining should be used.
  /// - Returns: The modified `URLRequest` instance.
  @available(macOS 10.15, iOS 13, *)
  @discardableResult
  func setHttpShouldUsePipelining(_ httpShouldUsePipelining: Bool) -> Self {
    var request = self
    request.httpShouldUsePipelining = httpShouldUsePipelining
    return request
  }

  /// Sets whether the `URLRequest` allows cellular access.
  ///
  /// - Parameter allowsCellularAccess: A Boolean value indicating whether cellular access is allowed.
  /// - Returns: The modified `URLRequest` instance.
  @available(macOS 10.15, iOS 13, *)
  @discardableResult
  func setAllowsCellularAccess(_ allowsCellularAccess: Bool) -> Self {
    var request = self
    request.allowsCellularAccess = allowsCellularAccess
    return request
  }

  /// Sets whether the `URLRequest` allows constrained network access.
  ///
  /// - Parameter allowsConstraintNetworkAccess: A Boolean value indicating whether constrained network access is allowed.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setAllowsConstraintNetworkAccess(_ allowsConstraintNetworkAccess: Bool) -> Self {
    var request = self
    request.allowsConstrainedNetworkAccess = allowsConstraintNetworkAccess
    return request
  }

  /// Sets whether the `URLRequest` allows expensive network access.
  ///
  /// - Parameter allowsExpensiveNetworkAccess: A Boolean value indicating whether expensive network access is allowed.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setAllowsExpensiveNetworkAccess(_ allowsExpensiveNetworkAccess: Bool) -> Self {
    var request = self
    request.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
    return request
  }

  /// Sets the network service type of the `URLRequest`.
  ///
  /// - Parameter networkServiceType: The network service type to set.
  /// - Returns: The modified `URLRequest` instance.
  @available(macOS 10.15, iOS 13, *)
  @discardableResult
  func setNetworkServiceType(_ networkServiceType: URLRequest.NetworkServiceType) -> Self {
    var request = self
    request.networkServiceType = networkServiceType
    return request
  }

  /// Sets whether the `URLRequest` assumes HTTP/3 capability.
  ///
  /// - Parameter assumesHTTP3Capable: A Boolean value indicating whether HTTP/3 capability is assumed.
  /// - Returns: The modified `URLRequest` instance.
  @available(macOS 11.3, iOS 14.5, watchOS 7.4, tvOS 14.5, *)
  @discardableResult
  func setAssumesHTTP3Capable(_ assumesHTTP3Capable: Bool) -> Self {
    var request = self
    request.assumesHTTP3Capable = assumesHTTP3Capable
    return request
  }
}

/* 
 Adds missing documentation for the `URLRequest` extension methods.
 */

@available(iOS 15, tvOS 15, macOS 12, watchOS 8, macCatalyst 15, *)
public extension URLRequest {
  /// Sets the attribution of the `URLRequest`.
  ///
  /// - Parameter attribution: The attribution to set.
  /// - Returns: The modified `URLRequest` instance.
  func setAttribution(_ attribution: URLRequest.Attribution) -> Self {
    var request = self
    request.attribution = attribution
    return request
  }
}

public extension URLRequest {
  /// Sets the `Content-Type` header of the `URLRequest`.
  ///
  /// - Parameter contentType: The `Content-Type` value to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func setContentType(_ contentType: String) -> Self {
    setHeader(.contentType(contentType))
  }

  /// Sets the `Content-Type` header of the `URLRequest` using an `HTTPContentType`.
  ///
  /// - Parameter contentType: The `HTTPContentType` value to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func setContentType(_ contentType: HTTPContentType) -> Self {
    setHeader(.contentType(contentType))
  }

  /// Sets the HTTP body of the `URLRequest` and optionally the `Content-Type` header using an `HTTPContentType`.
  ///
  /// - Parameters:
  ///   - httpBody: The HTTP body data to set.
  ///   - contentType: The `HTTPContentType` value to set for the `Content-Type` header. Defaults to `nil`.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func setHttpBody(_ httpBody: Data?, contentType: HTTPContentType? = nil) -> Self {
    setHttpBody(httpBody, contentType: contentType?.rawValue)
  }

  /// Sets the `User-Agent` header of the `URLRequest`.
  ///
  /// - Parameter userAgent: The `User-Agent` value to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func setUserAgent(_ userAgent: String) -> Self {
    setHeader(.userAgent(userAgent))
  }

  /// Sets the HTTP method of the `URLRequest` using an `HTTPMethod`.
  ///
  /// - Parameter method: The `HTTPMethod` value to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func setMethod(_ method: HTTPMethod?) -> Self {
    setHttpMethod(method?.rawValue)
  }

  /// Sets a single HTTP header field of the `URLRequest` using an `HTTPField`.
  ///
  /// - Parameter header: The `HTTPField` to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHeader(_ header: HTTPField?) -> Self {
    guard let header else {
      return self
    }
    return setHttpHeader(header.value, forField: header.name)
  }

  /// Sets multiple HTTP header fields of the `URLRequest` using an array of `HTTPField`.
  ///
  /// - Parameter headers: An array of `HTTPField` to set.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHeaders(_ headers: [HTTPField]?) -> Self {
    var request = self
    request.allHTTPHeaderFields = nil
    if let headers {
      request.headerFields = HTTPFields(headers)
    }
    return request
  }

  /// Adds a single HTTP header field to the `URLRequest` using an `HTTPField`.
  ///
  /// - Parameter header: The `HTTPField` to add.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  @inline(__always)
  func addHeader(_ header: HTTPField) -> Self {
    addHttpHeader(header.value, forField: header.name)
  }

  /// Adds multiple HTTP header fields to the `URLRequest` using an array of `HTTPField`.
  ///
  /// - Parameter headers: An array of `HTTPField` to add.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func addHeaders(_ headers: [HTTPField]) -> Self {
    var request = self
    for header in headers {
      request.addValue(header.value, forHTTPField: header.name)
    }
    return request
  }
}
