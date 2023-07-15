//
//  HTTPHeader.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation
import HTTPTypes

public struct HTTPHeader: Hashable, Identifiable {
    public let name: String
    public let value: String?

    public init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    public var id: String {
        name
    }
}

extension HTTPHeader: CustomStringConvertible {
    public var description: String {
        "\(name): \(value ?? "")"
    }
}

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
extension HTTPHeader: @unchecked Sendable {}

public extension HTTPHeader {
    init(field: HTTPField.Name, value: String? = nil) {
        self.name = field.canonicalName
        self.value = value
    }
}
