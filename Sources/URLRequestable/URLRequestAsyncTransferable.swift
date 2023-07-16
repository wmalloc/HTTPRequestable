//
//  URLRequestAsyncTransferable.swift
//  
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
import HTTPTypes

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public protocol URLRequestAsyncTransferable: URLRequestTransferable {
    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter request:    Request where to get the data from
     - parameter transform:  Transformer how to convert the data to different type

     - returns: Transformed Object
     */
    func data<ObjectType>(for request: URLRequest, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter route:    Request where to get the data from
     - parameter transform:  Transformer how to convert the data to different type

     - returns: Transformed Object
     */
    func data<ObjectType>(for route: any URLAsyncRequestable, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType
}

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public extension URLRequestAsyncTransferable {
    func data<ObjectType>(for request: URLRequest, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
        let result = try await session.data(for: request, delegate: delegate)
        return try await transformer(result)
    }

    func data<ObjectType>(for route: any URLAsyncRequestable, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
        let request = try route.urlRequest(headers: nil, queryItems: nil)
        return try await data(for: request, transformer: transformer, delegate: delegate)
    }
}
