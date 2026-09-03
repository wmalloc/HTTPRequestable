//
//  RequestTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

import Foundation
@testable import HackerNewsKit
import HTTPRequestable
import HTTPTypes
import Testing

@Suite("Requests")
struct RequestTests {
  let environment = HTTPEnvironment(authority: "hacker-news.firebaseio.com", path: "/v0")

  @Test("Story list URL joins the environment path with the story type")
  func storyListURL() throws {
    let request = try StoryListRequest(environment, storyType: "topstories")
    let url = try request.url
    #expect(url.absoluteString == "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
  }

  @Test("Story list URL for every story type", arguments: StoryType.allCases)
  func storyListURLForEveryType(type: StoryType) throws {
    let request = try StoryListRequest(environment, storyType: type.rawValue)
    let url = try request.url
    #expect(url.path == "/v0/\(type.rawValue).json")
  }

  @Test("Story list request asks for JSON with a pretty printed body")
  func storyListConfiguration() throws {
    let request = try StoryListRequest(environment, storyType: "newstories")
    #expect(request.method == .get)
    #expect(request.headerFields?[.accept] == "application/json")
    #expect(request.queryItems == [URLQueryItem(name: "print", value: "pretty")])
    #expect(request.httpBody == nil)
  }

  @Test("Story list decodes an array of identifiers")
  func storyListTransformer() throws {
    let request = try StoryListRequest(environment, storyType: "topstories")
    let ids = try request.responseDataTransformer(Data("[9129911, 9129199, 9127761]".utf8))
    #expect(ids == [9129911, 9129199, 9127761])
  }

  @Test("Item URL embeds the item identifier")
  func itemURL() throws {
    let request = try ItemRequest(environment, item: 8863)
    let url = try request.url
    #expect(url.absoluteString == "https://hacker-news.firebaseio.com/v0/item/8863.json")
  }

  @Test("Item request carries no query items or headers of its own")
  func itemConfiguration() throws {
    let request = try ItemRequest(environment, item: 1)
    #expect(request.method == .get)
    #expect(request.queryItems == nil)
    #expect(request.headerFields == nil)
    #expect(request.httpBody == nil)
  }

  @Test("Item request converts to a GET URLRequest")
  func itemURLRequest() throws {
    let request = try ItemRequest(environment, item: 42)
    let urlRequest = try request.urlRequest
    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://hacker-news.firebaseio.com/v0/item/42.json")
  }

  @Test("A non default environment is honoured")
  func customEnvironment() throws {
    let staging = HTTPEnvironment(authority: "example.com", scheme: "http", path: "/v1")
    let request = try StoryListRequest(staging, storyType: "beststories")
    let url = try request.url
    #expect(url.absoluteString == "http://example.com/v1/beststories.json?print=pretty")
  }
}
