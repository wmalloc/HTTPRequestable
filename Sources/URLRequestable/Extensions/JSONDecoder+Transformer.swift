//
//  JSONDecoder+Transformer.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public extension JSONDecoder {
  static func transformer<T: Decodable>(decoder: JSONDecoder = JSONDecoder()) -> Transformer<DataResponse, T> {
    { response in
        try response.response.url_validate()
      try response.data.url_validateNotEmptyData()
      return try decoder.decode(T.self, from: response.data)
    }
  }
}
