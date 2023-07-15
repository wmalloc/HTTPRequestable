//
//  URLRequest+Method.swift
//
//  Created by Waqar Malik on 7/12/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
    typealias Method = HTTPRequest.Method
}

public extension URLRequest {
    func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
        value(forHTTPHeaderField: field.canonicalName) ?? value(forHTTPHeaderField: field.rawName)
    }

    mutating func setValue(_ value: String?, forHTTPHeaderField field: HTTPField.Name) {
        setValue(value, forHTTPHeaderField: field.canonicalName)
    }

    mutating func addValue(_ value: String, forHTTPHeaderField field: HTTPField.Name) {
        self.addValue(value, forHTTPHeaderField: field.canonicalName)
    }
}
