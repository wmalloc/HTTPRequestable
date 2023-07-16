//
//  HackerNewsAPI.swift
//  
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
import URLRequestable

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
class HackerNewsAPI: URLRequestAsyncTransferable {
    let session: URLSession
    
    required init(session: URLSession = .shared) {
        self.session = session
    }
    
    func topStories() async throws -> TopStories.Response {
        let request = TopStories()
        return try await data(for: request, transformer: request.transformer)
    }
}

extension URLRequestable {
    var apiBaseURLString: String { "https://hacker-news.firebaseio.com" }
}

struct TopStories: URLRequestable {
    typealias Response = [Int]
    
    let method: URLRequest.Method = .get
    let path: String = "/v0/topstories.json"
    let headers: [HTTPHeader] = [.accept(.json)]
    let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]
}
