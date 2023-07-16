//
//  HTTPField.Name+Common.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
import HTTPTypes

public extension HTTPField.Name {
    static var userAuthorization: HTTPField.Name {
        .init("User-Authorization")!
    }
    
    static var xAPIKey: HTTPField.Name {
        .init("X-API-Key")!
    }
}
