//
//  HTTPHeaders+Defaults.swift
//
//
//  Created by Waqar Malik on 1/15/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import Foundation
import HTTPTypes

public extension HTTPHeaders {
	static var defaultHeaders: HTTPHeaders {
		HTTPHeaders(arrayLiteral: HTTPHeader.defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage)
	}
}

public extension HTTPHeaders {
    subscript(field: HTTPField.Name) -> String? {
        get {
            self[field.canonicalName] ?? self[field.rawName]
        }
        set {
            self[field.canonicalName] = newValue
        }
    }
}
