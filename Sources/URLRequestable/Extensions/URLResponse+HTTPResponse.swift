//
//  URLResponse+HTTPResponse.swift
//
//
//  Created by Waqar Malik on 3/9/24.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public extension URLResponse {
	var httpResponse: HTTPResponse {
		get throws {
			guard let httpResponse = try httpURLResponse.httpResponse else {
				throw URLError(.badServerResponse)
			}
			return httpResponse
		}
	}
  
  var httpURLResponse: HTTPURLResponse {
    get throws {
      guard let httpResponse = self as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
      }
      return httpResponse
    }
  }
}
