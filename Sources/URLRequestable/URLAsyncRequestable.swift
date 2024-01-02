//
//  URLAsyncRequestable.swift
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
public typealias AsyncTransformer<InputType, OutputType> = (InputType) async throws -> OutputType

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
public protocol URLAsyncRequestable: URLRequestable {
  var asyncTransformer: AsyncTransformer<Data, ResultType> { get }
}

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
public extension URLAsyncRequestable where ResultType: Decodable {
  var asyncTransformer: AsyncTransformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
