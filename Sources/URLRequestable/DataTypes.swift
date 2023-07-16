//
//  DataTypes.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public typealias DecodableHandler<T: Decodable> = (Result<T, Error>) -> Void
public typealias SerializableHandler = (Result<Any, Error>) -> Void
public typealias DataHandler<T> = (Result<T, Error>) -> Void
public typealias ErrorHandler = (Error?) -> Void
