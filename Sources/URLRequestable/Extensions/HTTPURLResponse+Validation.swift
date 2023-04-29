//
//  HTTPURLResponse+Validation.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public extension HTTPURLResponse {
    @discardableResult
    func url_httpValidate(acceptableStatusCodes: Range<Int> = 200 ..< 300, acceptableContentTypes: Set<String>? = nil) throws -> Self {
        guard acceptableStatusCodes.contains(statusCode) else {
            let errorCode = URLError.Code(rawValue: statusCode)
            throw URLError(errorCode)
        }

        if let validContentType = acceptableContentTypes {
            if let contentType = allHeaderFields[HTTPHeaderType.contentType] as? String {
                if !validContentType.contains(contentType) {
                    throw URLError(.dataNotAllowed)
                }
            } else {
                throw URLError(.badServerResponse)
            }
        }

        return self
    }
}
