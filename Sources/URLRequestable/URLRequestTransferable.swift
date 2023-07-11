//
//  URLRequestRetrievable.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Combine
import Foundation

public protocol URLRequestTransferable {
    var session: URLSession { get }
    
    init(session: URLSession)

    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter request:    Request where to get the data from
     - parameter transform:  Transformer how to convert the data to different type
     - parameter completion: completion handler

     - returns: URLSessionDataTask
     */
    func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<URLDataResponse, T>, completion: DataHandler<T>?) -> URLSessionDataTask?

    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter route:    Route to create URLRequest
     - parameter transform:  Transformer how to convert the data to different type
     - parameter completion: completion handler

     - returns: URLSessionDataTask
     */
    func dataTask<T>(for route: any URLRequestable, transformer: @escaping Transformer<URLDataResponse, T>, completion: DataHandler<T>?) -> URLSessionDataTask?

    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter request:    Request where to get the data from
     - parameter transform:  Transformer how to convert the data to different type

     - returns: Publisher with decoded response
     */
    func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<URLDataResponse, ObjectType>) -> AnyPublisher<ObjectType, Error>

    /**
     Make a request call and return decoded data as decoded by the transformer, this requesst must return data

     - parameter route:    Route to create URLRequest
     - parameter transform:  Transformer how to convert the data to different type

     - returns: Publisher with decoded response
     */
    func dataPublisher<ObjectType>(for route: any URLRequestable, transformer: @escaping Transformer<URLDataResponse, ObjectType>) -> AnyPublisher<ObjectType, Error>
}

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
    func data<ObjectType>(for route: any URLRequestable, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType
}

public extension URLRequestTransferable {
    @discardableResult
    func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<URLDataResponse, T>, completion: DataHandler<T>?) -> URLSessionDataTask? {
        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            if let error {
                completion?(.failure(error))
                return
            }

            guard let data, let urlResponse else {
                completion?(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                try urlResponse.url_validate()
                let mapped = try transformer((data, urlResponse))
                completion?(.success(mapped))
            } catch {
                completion?(.failure(error))
            }
        }
        dataTask.resume()
        return dataTask
    }

    @discardableResult
    func dataTask<T>(for route: any URLRequestable, transformer: @escaping Transformer<URLDataResponse, T>, completion: DataHandler<T>?) -> URLSessionDataTask? {
        guard let urlRequest = try? route.urlRequest(headers: nil, queryItems: nil) else {
            return nil
        }
        return dataTask(for: urlRequest, transformer: transformer, completion: completion)
    }
}

public extension URLRequestTransferable {
    func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<URLDataResponse, ObjectType>) -> AnyPublisher<ObjectType, Error> {
        session.dataTaskPublisher(for: request)
            .tryMap { result -> ObjectType in
                try result.response.url_validate()
                try result.data.url_validateNotEmptyData()
                return try transformer(result)
            }
            .eraseToAnyPublisher()
    }

    func dataPublisher<ObjectType>(for route: any URLRequestable, transformer: @escaping Transformer<URLDataResponse, ObjectType>) -> AnyPublisher<ObjectType, Error> {
        guard let urlRequest = try? route.urlRequest() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return dataPublisher(for: urlRequest, transformer: transformer)
    }
}

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public extension URLRequestAsyncTransferable {
    func data<ObjectType>(for request: URLRequest, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
        let result = try await session.data(for: request, delegate: delegate)
        return try await transformer(result)
    }

    func data<ObjectType>(for route: any URLRequestable, transformer: @escaping AsyncTransformer<URLDataResponse, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
        let request = try route.urlRequest(headers: nil, queryItems: nil)
        return try await data(for: request, transformer: transformer, delegate: delegate)
    }
}
