//
//  HTTPHeader+Common.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

public extension HTTPHeader {
    static func accept(_ value: String) -> Self {
        HTTPHeader(name: .accept, value: value)
    }

    static func acceptCharset(_ value: String) -> Self {
        HTTPHeader(name: .acceptCharset, value: value)
    }

    static func acceptLanguage(_ value: String) -> Self {
        HTTPHeader(name: .acceptLanguage, value: value)
    }

    static func acceptEncoding(_ value: String) -> Self {
        HTTPHeader(name: .acceptEncoding, value: value)
    }

    static func authorization(_ value: String) -> Self {
        HTTPHeader(name: .authorization, value: value)
    }

    static func authorization(token: String) -> Self {
        authorization("Bearer \(token)")
    }

    static func contentType(_ value: String) -> Self {
        HTTPHeader(name: .contentType, value: value)
    }

    static func userAgent(_ value: String) -> Self {
        HTTPHeader(name: .userAgent, value: value)
    }

    static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .contentDisposition, value: value)
    }
    
    /// See the [User-Agent header](https://tools.ietf.org/html/rfc7231#section-5.5.3).
    static var defaultUserAgent: HTTPHeader {
        .userAgent(String.url_userAgent)
    }
    
    static var defaultAcceptLanguage: HTTPHeader {
        .acceptLanguage(Locale.preferredLanguages.prefix(6).url_qualityEncoded())
    }

    static var defaultAcceptEncoding: HTTPHeader {
        .acceptEncoding(["br", "gzip", "deflate"].url_qualityEncoded())
    }
}
