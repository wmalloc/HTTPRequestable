//
//  HackerNewsAPI.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
import HTTPTypes
import URLRequestable

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
class HackerNewsAPI: HTTPTransferable {
	let session: URLSession

	required init(session: URLSession = .shared) {
		self.session = session
	}

	func storyList(type: String) async throws -> StoryList.ResultType {
		let request = try StoryList(storyType: type)
		return try await data(for: request, delegate: nil)
	}
}

struct StoryList: HTTPRequstable {
  typealias ResultType = [Int]
  
  let authority: String = "hacker-news.firebaseio.com"
	let method: URLRequest.Method = .get
	let path: String
	let headers: HTTPFields = .init([.accept(.json)])
	let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]

	init(storyType: String) throws {
		guard !storyType.isEmpty else {
			throw URLError(.badURL)
		}
		self.path = "/v0/" + storyType
	}
}
