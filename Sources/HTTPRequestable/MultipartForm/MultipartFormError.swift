//
//  MultipartFormError.swift
//
//  Created by Waqar Malik on 1/17/23
//

import Foundation

/// Errors thrown by multipart form
public enum MultipartFormError: LocalizedError, Sendable {
  case badURL(URL)
  case invalidFilename(URL)
  case fileNotFound(URL, (any Error)?)
  case fileAlreadyExists(URL)
  case accessDenied(URL)
  case fileIsDirectory(URL)
  case fileSizeNotAvailable(URL)
  case streamCreation(URL)
  case outputStreamWriteFailed(any Error)
  case inputStreamReadFailed(any Error)
  case inputStreamLength(String)

  public var errorDescription: String? {
    switch self {
    case .badURL(let url):
      String(localized: "multipart_error_invalid_url", bundle: .module) + " " + url.absoluteString

    case .invalidFilename(let url):
      String(localized: "multipart_error_invalid_filename", bundle: .module) + " " + url.absoluteString

    case .fileNotFound(let url, let error):
      String(localized: "multipart_error_file_notfound", bundle: .module) + " " + url.absoluteString + " " + (error?.localizedDescription ?? "")

    case .fileAlreadyExists(let url):
      String(localized: "multipart_error_file_already_exists", bundle: .module) + " " + url.absoluteString

    case .accessDenied(let url):
      String(localized: "multipart_error_access_denined", bundle: .module) + " " + url.absoluteString

    case .fileIsDirectory(let url):
      String(localized: "multipart_error_file_is_directory", bundle: .module) + " " + url.absoluteString

    case .fileSizeNotAvailable(let url):
      String(localized: "multipart_error_file_size_not_available", bundle: .module) + " " + url.absoluteString

    case .streamCreation(let url):
      String(localized: "multipart_error_stream_creation", bundle: .module) + " " + url.absoluteString

    case .outputStreamWriteFailed(let error):
      String(localized: "multipart_error_output_stream_write_failed", bundle: .module) + " " + error.localizedDescription

    case .inputStreamReadFailed(let error):
      String(localized: "multipart_error_input_stream_read_failed", bundle: .module) + " " + error.localizedDescription

    case .inputStreamLength(let message):
      String(localized: "multipart_error_input_stream_length", bundle: .module) + " " + message
    }
  }
}
