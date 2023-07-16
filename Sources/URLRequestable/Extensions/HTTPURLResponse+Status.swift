//
//  HTTPURLResponse+Status.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
import HTTPTypes

public extension HTTPURLResponse {
    typealias Status = HTTPResponse.Status
    
    var status: Status {
        Status(integerLiteral: self.statusCode)
    }
}

public extension HTTPURLResponse {
    func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
        value(forHTTPHeaderField: field.canonicalName) ?? value(forHTTPHeaderField: field.rawName)
    }
}

public extension Dictionary where Key == AnyHashable, Value == Any {
    func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
        (self[field.canonicalName] ?? self[field.rawName]) as? String
    }
}
