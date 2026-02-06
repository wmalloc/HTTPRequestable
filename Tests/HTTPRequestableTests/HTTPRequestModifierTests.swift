//
//  HTTPRequestModifierTests.swift
//
//  Created by Waqar Malik on 2/5/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

struct Test {
  @Test func defaultHTTPHeaderModifier() async throws {
    let defaultModifier = HTTPHeaderModifier.defaultHeaderModifier
    let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest
    httpRequest = try await httpRequest.apply([defaultModifier])
    #expect(httpRequest.headerFields[.acceptEncoding] == HTTPField.defaultAcceptEncoding.value)
    #expect(httpRequest.headerFields[.acceptLanguage] == HTTPField.defaultAcceptLanguage.value)
    #expect(httpRequest.headerFields[.userAgent] == HTTPField.defaultUserAgent.value)
  }

  @Test func defaultURLHeaderModifier() async throws {
    let defaultModifier = HTTPHeaderModifier.defaultHeaderModifier
    let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var urlRequest = try requestable.urlRequest
    urlRequest = try await urlRequest.apply([defaultModifier])
    #expect(urlRequest.value(forHTTPField: .acceptEncoding) == HTTPField.defaultAcceptEncoding.value)
    #expect(urlRequest.value(forHTTPField: .acceptLanguage) == HTTPField.defaultAcceptLanguage.value)
    #expect(urlRequest.value(forHTTPField: .userAgent) == HTTPField.defaultUserAgent.value)
  }
}
