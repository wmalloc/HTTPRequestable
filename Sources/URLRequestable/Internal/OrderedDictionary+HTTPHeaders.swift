//
//  OrderedDictionary+HTTPHeader.swift
//
//  Created by Waqar Malik on 5/31/23.
//

import Foundation
import OrderedCollections
import HTTPTypes

public typealias HTTPHeaders = OrderedDictionary<HTTPField.Name, String>

extension HTTPHeaders: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HTTPField...) {
        self.init()
        elements.forEach { self[$0.name] = $0.value }
    }
}

public extension HTTPHeaders {
    init(_ headers: [HTTPField]) {
        self.init()
        headers.forEach { self[$0.name] = $0.value}
    }
    
    var headers: [HTTPField] {
        elements.map { item in
            HTTPField(name: item.key, value: item.value)
        }
    }
    
    var dictionary: [String: String] {
        var dictionary: [String: String] = [:]
        self.forEach { item in
            dictionary[item.key.canonicalName] = item.value
        }
        return dictionary
    }
    
    func contains(_ header: HTTPField) -> Bool {
        self[header.name] != nil
    }
}
