//
//  Test.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

@testable import HTTPRequestable
import Testing
import HTTPTypes
import Foundation

struct RequestInterceptorTests {
  @Test func modifyHTTPRequest() async throws {
    let request = try StoryList(storyType: "topstories.json")
    var httpRequst = try request.httpRequest()
    #expect(httpRequst.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(httpRequst.method == .get)
    let modifier = AddContentTypeModifier()
    try await  modifier.intercept(&httpRequst, for: URLSession.shared)
    #expect(httpRequst.headerFields[.contentType] == HTTPContentType.json.rawValue)
  }
  
  @Test func modifyURLRequest() async throws {
    let request = try StoryList(storyType: "topstories.json")
    let modifier = AddContentTypeModifier()
    var urlRequest = try request.urlRequest()
    #expect(urlRequest.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
    #expect(urlRequest.httpMethod == "GET")
    try await modifier.intercept(&urlRequest, for: URLSession.shared)
    #expect(urlRequest.value(forHTTPHeaderField: HTTPField.Name.contentType.rawName) == HTTPContentType.jsonUTF8.rawValue)
  }

  class AddContentTypeModifier: RequestInterceptor {
    func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
      request.headerFields.append(HTTPField(name: .contentType, value: "application/json"))
    }
    
    func intercept(_ reqeust: inout URLRequest, for session: URLSession) async throws {
      reqeust.setValue(HTTPContentType.jsonUTF8.rawValue, forHTTPField: .contentType)
    }
  }
}
