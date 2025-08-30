//
//  Bundle+LoadData.swift
//
//
//  Created by Waqar Malik on 5/31/24.
//

import Foundation

/// Loads binary data from a bundle resource.
///
/// This convenience method is particularly handy in unit tests or when you
/// ship mock payloads with your app.  It attempts to locate the requested file
/// inside the bundle’s `MockData` sub‑directory (or another folder if you
/// specify one) and returns its contents as ``Data``.
///
/// ```swift
/// let json = try Bundle.main.data(forResource: "sample", withExtension: "json")
/// // json now contains the raw bytes of MockData/sample.json
/// ```
///
/// - Parameters:
///   - forResource: The name of the resource file *without* its extension.
///   - withExtension: The file’s extension (e.g. `"json"`, `"plist"`).
///   - subdirectory: Optional sub‑folder inside the bundle that contains the
///     resource.  Defaults to `"MockData"` which is a common convention for
///     test fixtures.
/// - Returns: A ``Data`` instance holding the file’s contents.
/// - Throws:
///   * `URLError.fileDoesNotExist` – if the URL could not be found in the bundle.
///   * Any error thrown by ``Data(contentsOf:options:)`` (e.g. read‑failure).
public extension Bundle {
  /// Loads data for a resource located in the bundle.
  ///
  /// The method first resolves the file’s URL using
  /// :method:`url(forResource:withExtension:subdirectory:)`.  If the URL is
  /// `nil`, it throws ``URLError.fileDoesNotExist``.  Otherwise, it reads the
  /// file into memory, mapping it to virtual memory if possible for
  /// efficiency.
  ///
  /// - Parameters:
  ///   - forResource: The resource name (without extension).
  ///   - withExtension: The file’s extension.
  ///   - subdirectory: A folder inside the bundle where the resource is
  ///     located; defaults to `"MockData"`.
  /// - Returns: The raw data of the requested file.
  /// - Throws: ``URLError`` if the file cannot be found, or any error from
  ///   ``Data(contentsOf:options:)``.
  func data(forResource resource: String, withExtension ext: String, subdirectory: String = "MockData") throws -> Data {
    guard let url = url(forResource: resource, withExtension: ext, subdirectory: subdirectory) else {
      throw URLError(.fileDoesNotExist)
    }
    return try Data(contentsOf: url, options: [.mappedIfSafe])
  }
}
