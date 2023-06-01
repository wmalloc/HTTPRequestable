//
//  OrderedDictionary+HTTPHeader.swift
//
//  Created by Waqar Malik on 5/31/23.
//

import Foundation
import OrderedCollections

extension HTTPHeaders: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init()
        elements.forEach { self[$0.name] = $0.value ?? "" }
    }
}

public extension HTTPHeaders {
    init(_ headers: [HTTPHeader]) {
        self.init()
        headers.forEach { self[$0.name] = $0.value ?? "" }
    }
    
    var headers: [HTTPHeader] {
        elements.map { item in
            HTTPHeader(name: item.key, value: item.value)
        }
    }
    
    var dictionary: [String: String] {
        var dictionary: [String: String] = [:]
        self.forEach { item in
            dictionary[item.key] = item.value
        }
        return dictionary
    }
    
    func contains(_ header: HTTPHeader) -> Bool {
        self[header.name] != nil
    }
}
