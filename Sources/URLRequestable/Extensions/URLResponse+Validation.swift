//
//  URLResponse+Validation.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public extension URLResponse {
	@discardableResult
	func url_validate(acceptableStatusCodes: Range<Int> = 200 ..< 300, acceptableContentTypes: Set<String>? = nil) throws -> Self {
		guard let httpResponse = self as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}
		try httpResponse.url_httpValidate(acceptableStatusCodes: acceptableStatusCodes, acceptableContentTypes: acceptableContentTypes)
		return self
	}
}
