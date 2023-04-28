//
//  HTTPMethod.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

/**
 Method to make web api calls

 Available cases:
 - **GET**: Requests a representation of the specified resource. Requests using `GET` should only retrieve data.
 - **POST**: Submits an entity to the specified resource, often causing a change in state or side effects on the server.
 - **PUT**: Replaces all current representations of the target resource with the request payload.
 - **PATCH**: Applies partial modifications to a resource.
 - **DELETE**:  Deletes the specified resource.
 - **.HEAD**: Asks for a response identical to a `GET` request, but without the response body.
 - **OPTIONS**: Describes the communication options for the target resource.
 - **TRACE**: Performs a message loop-back test along the path to the target resource.
 */

public enum HTTPMethod: String, CaseIterable, Hashable, Identifiable {
  case GET
  case POST
  case PUT
  case PATCH
  case DELETE
  case HEAD
  case OPTIONS
  case TRACE

  public var id: HTTPMethod {
    self
  }
}

extension HTTPMethod: CustomStringConvertible {
  public var description: String {
    rawValue
  }
}

@available(iOS 15, tvOS 15, watchOS 8, macCatalyst 15, macOS 12, *)
extension HTTPMethod: @unchecked Sendable {
}
