//
//  URLSessionConfiguration+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

public extension URLSessionConfiguration {
  var httpFields: HTTPFields {
    get { HTTPFields(rawValue: httpAdditionalHeaders as? [String: String] ?? [:]) }
    set { httpAdditionalHeaders = newValue.rawValue }
  }
}
