//
//  URLError+HTTPStatus.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation

extension URLError {
  /// The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).
  public static var badRequest: Self { .init(.badRequest) }

  /// Although the HTTP standard specifies "unauthorized", semantically this response means "unauthenticated". That is, the client must authenticate itself to get the requested response.
  public static var unauthorized: Self { .init(.unauthorized) }

  /// The client does not have access rights to the content; that is, it is unauthorized, so the server is refusing to give the requested resource. Unlike 401 Unauthorized, the client's identity is known to the server.
  static var forbidden: Self { .init(.forbidden) }

  /// The server cannot find the requested resource. In the browser, this means the URL is not recognized. In an API, this can also mean that the endpoint is valid but the resource itself does not exist.
  /// Servers may also send this response instead of 403 Forbidden to hide the existence of a resource from an unauthorized client.
  /// This response code is probably the most well known due to its frequent occurrence on the web.
  static var notFound: Self { .init(.notFound) }

  /// The request method is known by the server but is not supported by the target resource. For example, an API may not allow calling DELETE to remove a resource.
  static var methodNotAllowed: Self { .init(.methodNotAllowed) }

  /// This response is sent when the web server, after performing server-driven content negotiation, doesn't find any content that conforms to the criteria given by the user agent.
  static var notAcceptable: Self { .init(.notAcceptable) }

  /// This is similar to 401 Unauthorized but authentication is needed to be done by a proxy.
  static var proxyAuthenticationRequired: Self { .init(.proxyAuthenticationRequired) }

  /// This response is sent on an idle connection by some servers, even without any previous request by the client. It means that the server would like to shut down this unused connection.
  /// This response is used much more since some browsers, like Chrome, Firefox 27+, or IE9, use HTTP pre-connection mechanisms to speed up surfing.
  /// Also note that some servers merely shut down the connection without sending this message.
  static var requestTimeout: Self { .init(.requestTimeout) }

  /// This response is sent when a request conflicts with the current state of the server.
  static var conflict: Self { .init(.conflict) }

  /// This response is sent when the requested content has been permanently deleted from server, with no forwarding address. Clients are expected to remove their caches and links to the resource.
  /// The HTTP specification intends this status code to be used for "limited-time, promotional services". APIs should not feel compelled to indicate resources that have been deleted with this status code.
  static var gone: Self { .init(.gone) }

  /// Server rejected the request because the Content-Length header field is not defined and the server requires it.
  static var lengthRequired: Self { .init(.lengthRequired) }

  /// The client has indicated preconditions in its headers which the server does not meet.
  static var preconditionFailed: Self { .init(.preconditionFailed) }

  /// Request entity is larger than limits defined by server. The server might close the connection or return an Retry-After header field.
  static var payloadTooLarge: Self { .init(.payloadTooLarge) }

  /// The URI requested by the client is longer than the server is willing to interpret.
  static var uriTooLong: Self { .init(.uriTooLong) }

  /// The media format of the requested data is not supported by the server, so the server is rejecting the request.
  static var unsupportedMediaType: Self { .init(.unsupportedMediaType) }

  /// The range specified by the Range header field in the request cannot be fulfilled. It's possible that the range is outside the size of the target URI's data.
  static var rangeNotSatisfiable: Self { .init(.rangeNotSatisfiable) }

  /// This response code means the expectation indicated by the Expect request header field cannot be met by the server.
  static var expectationFailed: Self { .init(.expectationFailed) }

  /// The server refuses the attempt to brew coffee with a teapot.
  static var teapot: Self { .init(.teapot) }

  /// The request was directed at a server that is not able to produce a response. This can be sent by a server that is not configured to produce responses for the combination
  /// of scheme and authority that are included in the request URI.
  static var misdirectedRequest: Self { .init(.misdirectedRequest) }

  /// ndicates that the server is unwilling to risk processing a request that might be replayed.
  static var tooEarly: Self { .init(.tooEarly) }

  /// The server refuses to perform the request using the current protocol but might be willing to do so after the client upgrades to a different protocol.
  /// The server sends an Upgrade header in a 426 response to indicate the required protocol(s).
  static var upgradeRequired: Self { .init(.upgradeRequired) }

  /// The origin server requires the request to be conditional. This response is intended to prevent the 'lost update' problem, where a client GETs a resource's state,
  /// modifies it and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict.
  static var preconditionRequired: Self { .init(.preconditionRequired) }

  /// The user has sent too many requests in a given amount of time ("rate limiting").
  static var tooManyRequests: Self { .init(.tooManyRequests) }

  /// The server is unwilling to process the request because its header fields are too large. The request may be resubmitted after reducing the size of the request header fields.
  static var requestHeaderFieldsTooLarge: Self { .init(.requestHeaderFieldsTooLarge) }

  /// The user agent requested a resource that cannot legally be provided, such as a web page censored by a government.
  static var unavailableForLegalReasons: Self { .init(.unavailableForLegalReasons) }
}

///  A type that can be initialized with a string literal.
extension URLError.Code: @retroactive ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(rawValue: value)
  }
}

public extension URLError.Code {
  /// The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).
  static var badRequest: Self { 400 }

  /// Although the HTTP standard specifies "unauthorized", semantically this response means "unauthenticated". That is, the client must authenticate itself to get the requested response.
  static var unauthorized: Self { 401 }

  /// The client does not have access rights to the content; that is, it is unauthorized, so the server is refusing to give the requested resource. Unlike 401 Unauthorized, the client's identity is known to the server.
  static var forbidden: Self { 403 }

  /// The server cannot find the requested resource. In the browser, this means the URL is not recognized. In an API, this can also mean that the endpoint is valid but the resource itself does not exist.
  /// Servers may also send this response instead of 403 Forbidden to hide the existence of a resource from an unauthorized client.
  /// This response code is probably the most well known due to its frequent occurrence on the web.
  static var notFound: Self { 404 }

  /// The request method is known by the server but is not supported by the target resource. For example, an API may not allow calling DELETE to remove a resource.
  static var methodNotAllowed: Self { 405 }

  /// This response is sent when the web server, after performing server-driven content negotiation, doesn't find any content that conforms to the criteria given by the user agent.
  static var notAcceptable: Self { 406 }

  /// This is similar to 401 Unauthorized but authentication is needed to be done by a proxy.
  static var proxyAuthenticationRequired: Self { 407 }

  /// This response is sent on an idle connection by some servers, even without any previous request by the client. It means that the server would like to shut down this unused connection.
  /// This response is used much more since some browsers, like Chrome, Firefox 27+, or IE9, use HTTP pre-connection mechanisms to speed up surfing.
  /// Also note that some servers merely shut down the connection without sending this message.
  static var requestTimeout: Self { 408 }

  /// This response is sent when a request conflicts with the current state of the server.
  static var conflict: Self { 409 }

  /// This response is sent when the requested content has been permanently deleted from server, with no forwarding address. Clients are expected to remove their caches and links to the resource.
  /// The HTTP specification intends this status code to be used for "limited-time, promotional services". APIs should not feel compelled to indicate resources that have been deleted with this status code.
  static var gone: Self { 410 }

  /// Server rejected the request because the Content-Length header field is not defined and the server requires it.
  static var lengthRequired: Self { 411 }

  /// The client has indicated preconditions in its headers which the server does not meet.
  static var preconditionFailed: Self { 412 }

  /// Request entity is larger than limits defined by server. The server might close the connection or return an Retry-After header field.
  static var payloadTooLarge: Self { 413 }

  /// The URI requested by the client is longer than the server is willing to interpret.
  static var uriTooLong: Self { 414 }

  /// The media format of the requested data is not supported by the server, so the server is rejecting the request.
  static var unsupportedMediaType: Self { 415 }

  /// The range specified by the Range header field in the request cannot be fulfilled. It's possible that the range is outside the size of the target URI's data.
  static var rangeNotSatisfiable: Self { 416 }

  /// This response code means the expectation indicated by the Expect request header field cannot be met by the server.
  static var expectationFailed: Self { 417 }

  /// The server refuses the attempt to brew coffee with a teapot.
  static var teapot: Self { 418 }

  /// The request was directed at a server that is not able to produce a response. This can be sent by a server that is not configured to produce responses for the combination
  /// of scheme and authority that are included in the request URI.
  static var misdirectedRequest: Self { 421 }

  /// ndicates that the server is unwilling to risk processing a request that might be replayed.
  static var tooEarly: Self { 425 }

  /// The server refuses to perform the request using the current protocol but might be willing to do so after the client upgrades to a different protocol.
  /// The server sends an Upgrade header in a 426 response to indicate the required protocol(s).
  static var upgradeRequired: Self { 426 }

  /// The origin server requires the request to be conditional. This response is intended to prevent the 'lost update' problem, where a client GETs a resource's state,
  /// modifies it and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict.
  static var preconditionRequired: Self { 428 }

  /// The user has sent too many requests in a given amount of time ("rate limiting").
  static var tooManyRequests: Self { 429 }

  /// The server is unwilling to process the request because its header fields are too large. The request may be resubmitted after reducing the size of the request header fields.
  static var requestHeaderFieldsTooLarge: Self { 431 }

  /// The user agent requested a resource that cannot legally be provided, such as a web page censored by a government.
  static var unavailableForLegalReasons: Self { 433 }
}
