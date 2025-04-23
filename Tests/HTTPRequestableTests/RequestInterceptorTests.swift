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
    Task {
      let logger = LoggerInterceptor()
      await api.requestInterceptors.append(logger)
      await api.responseInterceptors.append(logger)
    }
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

  @Test func storageTests() async throws {
    let storage = AsyncArray<any HTTPRequestInterceptor>()
    #expect(await storage.isEmpty)
    await storage.append(OSLogInterceptor())
    #expect(await !storage.isEmpty)
    #expect(await storage.count == 1)
    await storage.remove(at: 0)
    #expect(await storage.isEmpty)
    #expect(await storage.count == 0)
    await storage.append(OSLogInterceptor())
    await storage.append(LoggerInterceptor())
    #expect(await storage.count == 2)
    await storage.append(AddContentTypeModifier())
  }

  final class AddContentTypeModifier: HTTPRequestInterceptor {
    func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
      request.headerFields.append(HTTPField(name: .contentType, value: "application/json"))
    }

    func intercept(_ reqeust: inout URLRequest, for session: URLSession) async throws {
      reqeust.setValue(HTTPContentType.jsonUTF8.rawValue, forHTTPField: .contentType)
    }
  }
}
