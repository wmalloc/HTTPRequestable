//
//  HTTPHeaders.swift
//
//  Created by Waqar Malik on 5/31/23.
//

import Foundation
import OrderedCollections

public struct HTTPHeaders: Hashable {
    private(set) var storage: OrderedDictionary<String, HTTPHeader>
    
    public init() {
        self.storage = [:]
    }
    
    public init(_ dictionary: OrderedDictionary<String, HTTPHeader>) {
        self.storage = dictionary
    }
    
    public init(_ headers: [HTTPHeader]) {
        storage = [:]
        self.headers = headers
    }
    
    public var headers: [HTTPHeader] {
        get {
            Array(storage.values)
        }
        set {
            storage.removeAll()
            let headers: [String: HTTPHeader] = newValue.reduce([:]) { partialResult, header in
                var result = partialResult
                result[header.name] = header
                return result
            }
            update(headers)
        }
    }
    
    public mutating func update(_ headers: [String: HTTPHeader]) {
        self.storage.merge(headers) { _, header in
            header
        }
    }
    
    public mutating func update(_ header: HTTPHeader) {
        self.storage[header.name] = header
    }

    public mutating func update(_ header: (key: String, value: HTTPHeader)) {
        update(header.value)
    }
    
    public mutating func update(name: String, value: String) {
        update(HTTPHeader(name: name, value: value))
    }
    
    @discardableResult
    public mutating func remove(name: String) -> HTTPHeader? {
        storage.removeValue(forKey: name)
    }
    
    public mutating func sort() {
        storage.sort { lhs, rhs in
            rhs.key.lowercased() < rhs.key.lowercased()
        }
    }
    
    public func sorted() -> Self {
        var sorted = self.storage
        sorted.sort { lhs, rhs in
            rhs.key.lowercased() < rhs.key.lowercased()
        }
        return HTTPHeaders(sorted)
    }
    
    public func value(for name: String) -> String? {
        storage[name]?.value
    }

    public subscript(_ name: String) -> String? {
        get {
            value(for: name)
        }

        set {
            if let newValue {
                update(name: name, value: newValue)
            } else {
                remove(name: name)
            }
        }
    }
}

extension HTTPHeaders: CustomStringConvertible {
    public var description: String {
        (headers.map { header in
            header.description
        }).joined(separator: "\n")
    }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        storage = [:]
        
        = elements.map { name, value in
            HTTPHeader(name: name, value: value)
        }
    }
}

extension HTTPHeaders: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(elements)
    }
}

extension HTTPHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
        headers.makeIterator()
    }
}

extension HTTPHeaders: Collection {
    public var startIndex: Int {
        headers.startIndex
    }

    public var endIndex: Int {
        headers.endIndex
    }

    public subscript(position: Int) -> HTTPHeader {
        headers[position]
    }

    public func index(after index: Int) -> Int {
        headers.index(after: index)
    }
}

extension Array where Element == HTTPHeader {
    func firstIndex(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex {
            $0.name.lowercased() == lowercasedName
        }
    }
}
