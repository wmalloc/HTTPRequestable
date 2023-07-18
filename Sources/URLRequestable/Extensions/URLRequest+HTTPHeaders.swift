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
	func setHttpHeaders(_ httpHeaders: HTTPHeaders?) -> Self {
		var request = self
		request.headers = httpHeaders
		return request
	}

	@discardableResult
	func addHeaders(_ headers: HTTPHeaders) -> Self {
		addHeaders(headers.headers)
	}
    
    @discardableResult
    func setMultipartFormData(_ multipartFormData: MultipartFormData) throws -> Self {
        let request = self
        request.setHttpBody(try multipartFormData.encoded(), contentType: multipartFormData.contentType)
            .setHeader(HTTPField(name: .contentLength, value: "\(multipartFormData.contentLength)"))
            .setHeader(HTTPField(name: .contentType, value: multipartFormData.contentType))
        return self
    }
}

public extension URLRequest {
	var headers: HTTPHeaders? {
		get {
            let values: [HTTPField]? = allHTTPHeaderFields?.compactMap { (key: String, value: String) in
                guard let name = HTTPField.Name(key) else {
                    return nil
                }
                return HTTPField(name: name, value: value)
			}
			guard let values else {
				return nil
			}
			return HTTPHeaders(values)
		}
		set {
			allHTTPHeaderFields = newValue?.dictionary
		}
	}
}
