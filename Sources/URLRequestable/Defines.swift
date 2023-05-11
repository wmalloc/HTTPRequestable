//
//  Defines.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public typealias DecodableHandler<T: Decodable> = (Result<T, Error>) -> Void
public typealias SerializableHandler = (Result<Any, Error>) -> Void
public typealias DataHandler<T> = (Result<T, Error>) -> Void
public typealias ErrorHandler = (Error?) -> Void
public typealias Transformer<InputType, OutputType> = (InputType) throws -> OutputType
public typealias DataResponse = (data: Data, response: URLResponse)

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
public typealias AsyncTransformer<InputType, OutputType> = (InputType) async throws -> OutputType
