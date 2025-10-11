//
//  MultipartFormBoundaryType.swift
//
//  Created by Waqar Malik on 1/24/23
//

import Foundation

public enum EncodingCharacters: Sendable {
  public static let crlf = "\r\n"
}

public enum MultipartFormBoundaryType: Hashable, Identifiable, CaseIterable, Sendable {
  public var id: MultipartFormBoundaryType {
    self
  }

  case initial // --boundary
  case interstitial // --boundary
  case final // --boundary--

  public static func boundaryData(forBoundaryType boundaryType: MultipartFormBoundaryType, boundary: String) -> Data {
    Data(self.boundary(forBoundaryType: boundaryType, boundary: boundary).utf8)
  }

  public static func boundary(forBoundaryType boundaryType: MultipartFormBoundaryType, boundary: String) -> String {
    switch boundaryType {
    case .initial:
      "--\(boundary)\(EncodingCharacters.crlf)"

    case .interstitial:
      "\(EncodingCharacters.crlf)--\(boundary)\(EncodingCharacters.crlf)"

    case .final:
      "\(EncodingCharacters.crlf)--\(boundary)--\(EncodingCharacters.crlf)"
    }
  }
}
