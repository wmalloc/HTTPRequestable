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
  /// Creates a list from `values` in order of preference, with q-values falling from `1.0`.
  ///
  /// The q-value falls by `0.1` per item, or by less when there are more than ten items, so every item
  /// stays above `0` (which would mark it as not acceptable). The lowest q-value is `0.001`.
  ///
  /// ```swift
  /// try Quality(values: ["br", "gzip", "deflate"]).encoded  // "br;q=1.0,gzip;q=0.9,deflate;q=0.8"
  /// ```
  ///
  /// - Parameter values: The values, most preferred first. Each must be a token or a media range.
  /// - Throws: ``HTTPFieldValueError/invalidItem`` when a value is not a token or a media range.
  init(values: [String]) throws {
    let step = values.isEmpty ? 0.1 : Swift.min(0.1, 1 / Double(values.count))
    let items = try values.enumerated().map { index, value in
      let quality = Swift.max(1.0 - Double(index) * step, 0.001)
      return try Quality.Item(item: value, parameters: Parameter(uncheckedQ: Float(quality)))
    }

    self.init(items)
  }
}

extension Quality {
  /// A list made from the valid values in `values`, in order of preference.
  ///
  /// Used for default headers built from system values, such as the preferred languages, where one
  /// unusual value should not stop the header from being sent. Values that are not tokens or media
  /// ranges are left out.
  init(validValuesOf values: [String]) {
    // The filter leaves only valid items, so the initializer cannot throw.
    self = (try? Quality(values: values.filter(HTTPFieldValueSyntax.isItem))) ?? []
  }
}
