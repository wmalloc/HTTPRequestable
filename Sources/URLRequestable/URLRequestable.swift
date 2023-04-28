//
//  URLRequestable.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public protocol URLRequestable {
    associatedtype Response

    typealias ResponseTransformer = Transformer<DataResponse, Response>

    var apiBaseURLString: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [HTTPHeader] { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }

    var transformer: ResponseTransformer { get }

    func url(queryItems: [URLQueryItem]?) throws -> URL
    func urlRequest(headers: [HTTPHeader]?, queryItems: [URLQueryItem]?) throws -> URLRequest
}

public extension URLRequestable {
    var method: HTTPMethod {
        .GET
    }
    
    var headers: [HTTPHeader] {
        [.accept(.json), .defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage]
    }

    var body: Data? {
        nil
    }

    var queryItems: [URLQueryItem]? {
        nil
    }
    
    func url(queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard var components = URLComponents(string: apiBaseURLString) else {
            throw URLError(.badURL)
        }
        var items = self.queryItems ?? []
        items.append(contentsOf: queryItems ?? [])
        components = components
            .appendQueryItems(items)
            .setPath(path)
        guard let url = components.url else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
    
    func urlRequest(headers: [HTTPHeader]? = nil, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
        let url = try url(queryItems: queryItems)
        let request = URLRequest(url: url)
            .setMethod(method)
            .addHeaders(self.headers)
            .addHeaders(headers ?? [])
            .setHttpBody(body, contentType: .json)
        return request
    }
}

public extension URLRequestable where Response: Decodable {
    var transformer: ResponseTransformer {
        JSONDecoder.transformer()
    }
}
