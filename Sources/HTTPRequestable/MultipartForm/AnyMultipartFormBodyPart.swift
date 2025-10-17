//
//  AnyMultipartFormBodyPart.swift
//
//  Created by Waqar Malik on 5/24/24.
//

import Foundation
import HTTPTypes

/// A type-erased representation of a single body part in a multipart/form-data payload.
///
/// Conforming types encapsulate the headers and content associated with one
/// part of a multipart request body (for example, a text field or a file).
/// Each body part is responsible for providing its HTTP headers, reporting its
/// content length, and producing its encoded data when requested.
///
/// Typical usage involves composing multiple `AnyMultipartFormBodyPart`
/// instances into a complete multipart/form-data body, where each part:
/// - Supplies its own headers (e.g., `Content-Disposition`, `Content-Type`)
/// - Knows the exact byte length of its content
/// - Can serialize itself into `Data`, optionally using a streaming buffer size
///
/// Conformance notes:
/// - `headers` should include only the headers that belong to this part,
///   not the multipart boundary lines or global request headers.
/// - `contentLength` must reflect the exact number of bytes of the part’s
///   content (excluding the encoded headers and CRLFs that precede/follow it).
/// - `encodedHeadersData` is provided by a default implementation that formats
///   the part’s headers as HTTP header lines terminated by CRLF and followed by
///   an additional CRLF to separate headers from the body.
/// - `data(streamBufferSize:)` should return the raw body data for the part.
///   Implementations may ignore `streamBufferSize` if they don’t stream, but
///   should honor it when reading large content from disk or network sources.
///
/// Thread-safety:
/// - Implementations should document whether properties and methods are safe to
///   call from multiple threads concurrently.
///
/// Error handling:
/// - `data(streamBufferSize:)` may throw if generating or reading the content
///   fails (e.g., file I/O errors).
public protocol AnyMultipartFormBodyPart {
  /// The HTTP headers specific to this body part.
  ///
  /// Common headers include:
  /// - `Content-Disposition` (often with `form-data; name="..."; filename="..."`)
  /// - `Content-Type` (e.g., `text/plain`, `image/png`, `application/octet-stream`)
  ///
  /// Do not include the multipart boundary lines here; they are managed by the
  /// multipart container.
  var headers: [HTTPField] { get }

  /// The exact length, in bytes, of the body part’s content.
  ///
  /// This value should represent only the content payload, not the header lines
  /// nor any boundary or CRLF delimiters added by the multipart container.
  var contentLength: UInt64 { get }

  /// The serialized headers for this body part, encoded as UTF-8 data.
  ///
  /// The default implementation formats each header as `Name: Value` followed by
  /// CRLF, then appends an additional CRLF to separate headers from the body.
  ///
  /// This data is suitable for direct inclusion in a multipart/form-data stream
  /// immediately before the part’s body content.
  var encodedHeadersData: Data { get }

  /// Produces the raw content data for this body part.
  ///
  /// - Parameter streamBufferSize: A suggested buffer size (in bytes) for
  ///   streaming or chunked reads. Implementations may use this value to control
  ///   memory usage when loading large payloads (e.g., from disk). Implementations
  ///   that already hold the content in memory may ignore this parameter.
  /// - Returns: The complete content payload for this part as `Data`.
  /// - Throws: An error if the content cannot be generated or read (e.g., file I/O
  ///   failures, encoding errors).
  func data(streamBufferSize: Int) throws -> Data
}

/// The default implementation for `encodedHeadersData` on `AnyMultipartFormBodyPart`.
///
/// It joins all headers into HTTP-style lines with CRLF endings and appends a final
/// CRLF to mark the end of the header section before the body. This behavior matches
/// multipart/form-data formatting expectations and should be suitable for most cases.
public extension AnyMultipartFormBodyPart {
  var encodedHeadersData: Data {
    let headerText = headers.map { field in
      "\(field.name): \(field.value)\(String.crlf)"
    }
    .joined()
    + String.crlf
    return Data(headerText.utf8)
  }
}
