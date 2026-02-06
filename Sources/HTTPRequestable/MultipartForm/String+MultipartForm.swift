//
//  String+MultipartForm.swift
//
//  Created by Waqar Malik on 10/15/25.
//

import Foundation

extension String {
  static var crlf: Self {
    "\r\n"
  }

  var initialBoundary: Self {
    "--\(self)\(String.crlf)"
  }

  var interstitialBoundary: Self {
    "\(String.crlf)--\(self)\(String.crlf)"
  }

  var finalBoundary: Self {
    "\(String.crlf)--\(self)--\(String.crlf)"
  }

  var initialBoundaryData: Data {
    Data(initialBoundary.utf8)
  }

  var interstitialBoundaryData: Data {
    Data(interstitialBoundary.utf8)
  }

  var finalBoundaryData: Data {
    Data(finalBoundary.utf8)
  }
}
