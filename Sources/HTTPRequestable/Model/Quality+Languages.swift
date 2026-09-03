//
//  Quality+Languages.swift
//
//  Created by Waqar Malik on 10/25/24.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public extension Quality {
  init(values: [String]) {
    let items = values.enumerated().map { index, lang in
      Quality.Item(item: lang, parameters: Parameter(double: 1.0 - (Double(index) * 0.1)))
    }

    self.init(items)
  }
}
