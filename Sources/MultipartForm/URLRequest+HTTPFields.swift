//
//  URLRequest+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import Foundation
import HTTPTypes
import URLRequestable

public extension URLRequest {
	@discardableResult
	func setMultipartFormData(_ multipartFormData: MultipartFormData) throws -> Self {
		let request = self
		try request.setHttpBody(multipartFormData.encoded(), contentType: multipartFormData.contentType)
			.setHeader(HTTPField(name: .contentLength, value: "\(multipartFormData.contentLength)"))
			.setHeader(HTTPField(name: .contentType, value: multipartFormData.contentType))
		return self
	}
}
