//
//  URLRequest+Method.swift
//
//  Created by Waqar Malik on 7/12/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
	func value(forHTTPField name: HTTPField.Name) -> String? {
		value(forHTTPHeaderField: name.canonicalName) ?? value(forHTTPHeaderField: name.rawName)
	}

	mutating func setValue(_ value: String?, forHTTPField name: HTTPField.Name) {
		setValue(value, forHTTPHeaderField: name.rawName)
	}

	mutating func addValue(_ value: String, forHTTPField name: HTTPField.Name) {
		addValue(value, forHTTPHeaderField: name.rawName)
	}

	subscript(header key: String) -> String? {
		get {
			value(forHTTPHeaderField: key)
		}
		set {
			setValue(newValue, forHTTPHeaderField: key)
		}
	}

	subscript(field: HTTPField.Name) -> String? {
		get {
			value(forHTTPField: field)
		}
		set {
			setValue(newValue, forHTTPField: field)
		}
	}

	var contentType: String? {
		get {
			self[.contentType]
		}
		set {
			self[.contentType] = newValue
		}
	}

	var userAgent: String? {
		get {
			self[.userAgent]
		}
		set {
			self[.userAgent] = newValue
		}
	}
}
