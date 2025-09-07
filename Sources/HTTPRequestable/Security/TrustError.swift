//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation

public enum TrustError: Error {
  case certificateNotFound
  case certificatesDoNotMatch
}
