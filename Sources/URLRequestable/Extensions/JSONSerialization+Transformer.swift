//
//  JSONSerialization+Transformer.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public extension JSONSerialization {
  static func transformer(options: JSONSerialization.ReadingOptions = .allowFragments) -> Transformer<DataResponse, Any> {
    { response in
      try response.response.url_validate()
      try response.data.url_validateNotEmptyData()
      return try JSONSerialization.jsonObject(with: response.data, options: options)
    }
  }
}
