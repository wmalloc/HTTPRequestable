//
//  URLRequest+HTTPHeaders.swift
//
//  Created by Waqar Malik on 1/14/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import Foundation
import HTTPTypes

public extension URLRequest {
	@discardableResult
	func setHttpHeaderFields(_ fields: HTTPFields?) -> Self {
		var request = self
		request.headerFields = fields
		return request
	}

	@discardableResult
	func addHeaderFields(_ fields: HTTPFields?) -> Self {
		guard let fields else {
			return self
		}
		var request = self
		for header in fields {
			request.addValue(header.value, forHTTPHeaderField: header.name)
		}
		return request
	}

	@discardableResult
	func setMultipartFormData(_ multipartFormData: MultipartFormData) throws -> Self {
		let request = self
		try request.setHttpBody(multipartFormData.encoded(), contentType: multipartFormData.contentType)
			.setHeader(HTTPField(name: .contentLength, value: "\(multipartFormData.contentLength)"))
			.setHeader(HTTPField(name: .contentType, value: multipartFormData.contentType))
		return self
	}
}

public extension URLRequest {
	var headerFields: HTTPFields? {
		get {
			guard let allHTTPHeaderFields else {
				return nil
			}
			return HTTPFields(rawValue: allHTTPHeaderFields)
		}
		set {
			allHTTPHeaderFields = newValue?.rawValue
		}
	}
}

extension HTTPFields: RawRepresentable {
	public typealias RawValue = [String: String]

	public init?(rawValue: [String: String]) {
		self.init()
		for (key, value) in rawValue {
			guard let name = HTTPField.Name(key) else {
				continue
			}
			self[name] = value
		}
	}

	public var rawValue: [String: String] {
		var rawValues: [String: String] = [:]
        for value in self {
            rawValues[value.name.canonicalName] = value.value
        }
		return rawValues
	}
}
