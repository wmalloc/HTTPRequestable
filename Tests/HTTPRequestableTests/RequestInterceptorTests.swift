//
//  RequestInterceptorTests.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Testing

struct RequestInterceptorTests {
  let hackerNews: HackerNews = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let api = HackerNews(session: session)
    let logger = LoggerInterceptor()
    api.requestInterceptors.append(logger)
    api.responseInterceptors.append(logger)
    return api
  }()

  @Test func modifyHTTPRequest() async throws {
    let request = try StoryListRequest(environment: hackerNews.environment, storyType: "topstories")
    var httpRequst = try request.httpRequest
    #expect(httpRequst.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(httpRequst.method == .get)
    let modifier = AddContentTypeModifier()
    try await modifier.intercept(&httpRequst, for: URLSession.shared)
    #expect(httpRequst.headerFields[.contentType] == HTTPContentType.json.rawValue)
  }

  @Test func modifyURLRequest() async throws {
    let request = try StoryListRequest(environment: hackerNews.environment, storyType: "topstories")
    let modifier = AddContentTypeModifier()
    var urlRequest = try request.urlRequest
    #expect(urlRequest.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(urlRequest.httpMethod == "GET")
    try await modifier.intercept(&urlRequest, for: URLSession.shared)
    #expect(urlRequest.value(forHTTPHeaderField: HTTPField.Name.contentType.rawName) == HTTPContentType.jsonUTF8.rawValue)
  }

  class AddContentTypeModifier: HTTPRequestInterceptor {
    func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
      request.headerFields.append(HTTPField(name: .contentType, value: "application/json"))
    }

    func intercept(_ reqeust: inout URLRequest, for session: URLSession) async throws {
      reqeust.setValue(HTTPContentType.jsonUTF8.rawValue, forHTTPField: .contentType)
    }
  }
}
