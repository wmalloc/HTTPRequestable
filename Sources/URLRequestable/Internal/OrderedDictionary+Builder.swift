//
//  OrderedDictionary+Builder.swift
//
//  Created by Waqar Malik on 5/31/23.
//

import Foundation
import OrderedCollections

public extension HTTPHeaders {
    func add(_ header: HTTPHeader) -> Self {
        var headers = self
        headers[header.name] = header.value ?? ""
        return headers
    }
}
