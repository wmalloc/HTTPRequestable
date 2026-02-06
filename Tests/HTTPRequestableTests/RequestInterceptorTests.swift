//
//  RequestInterceptorTests.swift
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
    return HackerNews(session: session)
  }()

  @Test func modifyHTTPRequest() async throws {
    let request = try StoryListRequest(hackerNews.environment, storyType: "topstories")
    var httpRequst = try request.httpRequest
    #expect(httpRequst.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(httpRequst.method == .get)
    let modifier = AddContentTypeModifier()
    try await modifier.modify(&httpRequst, for: nil)
    #expect(httpRequst.headerFields[.contentType] == HTTPContentType.json.rawValue)
  }

  @Test func modifyURLRequest() async throws {
    let request = try StoryListRequest(hackerNews.environment, storyType: "topstories")
    let modifier = AddContentTypeModifier()
    var urlRequest = try request.urlRequest
    #expect(urlRequest.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(urlRequest.httpMethod == "GET")
    try await modifier.modify(&urlRequest, for: nil)
    #expect(urlRequest.value(forHTTPHeaderField: HTTPField.Name.contentType.rawName) == HTTPContentType.jsonUTF8.rawValue)
  }

  @Test func storageTests() {
    var storage = [any HTTPRequestModifier]()
    #expect(storage.isEmpty)
    storage.append(OSLogInterceptor())
    #expect(!storage.isEmpty)
    #expect(storage.count == 1)
    storage.remove(at: 0)
    #expect(storage.isEmpty)
    #expect(storage.isEmpty)
    storage.append(OSLogInterceptor())
    storage.append(LoggerInterceptor())
    #expect(storage.count == 2)
    storage.append(AddContentTypeModifier())
  }

  final class AddContentTypeModifier: HTTPRequestModifier {
    func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
      request.headerFields.append(HTTPField(name: .contentType, value: "application/json"))
    }

    func modify(_ reqeust: inout URLRequest, for session: URLSession?) async throws {
      reqeust.setValue(HTTPContentType.jsonUTF8.rawValue, forHTTPField: .contentType)
    }
  }
}
