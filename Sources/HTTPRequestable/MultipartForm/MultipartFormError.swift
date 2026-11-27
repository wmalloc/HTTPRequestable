//
//  MultipartFormError.swift
//
//  Created by Waqar Malik on 1/17/23
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
      MultipartFormError.Message.badURL + " " + url.absoluteString

    case .invalidFilename(let url):
      MultipartFormError.Message.invalidFilename + " " + url.absoluteString

    case .fileNotFound(let url, let error):
      MultipartFormError.Message.fileNotFound + " " + url.absoluteString + " " + (error?.localizedDescription ?? "")

    case .fileAlreadyExists(let url):
      MultipartFormError.Message.fileAlreadyExists + " " + url.absoluteString

    case .accessDenied(let url):
      MultipartFormError.Message.accessDenied + " " + url.absoluteString

    case .fileIsDirectory(let url):
      MultipartFormError.Message.fileIsDirectory + " " + url.absoluteString

    case .fileSizeNotAvailable(let url):
      MultipartFormError.Message.fileSizeNotAvailable + " " + url.absoluteString

    case .streamCreation(let url):
      MultipartFormError.Message.streamCreation + " " + url.absoluteString

    case .outputStreamWriteFailed(let error):
      MultipartFormError.Message.outputStreamWriteFailed + " " + error.localizedDescription

    case .inputStreamReadFailed(let error):
      MultipartFormError.Message.inputStreamReadFailed + " " + error.localizedDescription

    case .inputStreamLength(let message):
      MultipartFormError.Message.inputStreamLength + " " + message
    }
  }
}

extension MultipartFormError {
  /// The text that begins each error's ``errorDescription``.
  enum Message {
    static var badURL: String {
      "Bad URL"
    }

    static var invalidFilename: String {
      "Invalid filename"
    }

    static var fileNotFound: String {
      "File not found"
    }

    static var fileAlreadyExists: String {
      "File already exists"
    }

    static var accessDenied: String {
      "Access Denied"
    }

    static var fileIsDirectory: String {
      "File is directory"
    }

    static var fileSizeNotAvailable: String {
      "File size not available"
    }

    static var streamCreation: String {
      "Stream creation"
    }

    static var outputStreamWriteFailed: String {
      "Output stream write failed"
    }

    static var inputStreamReadFailed: String {
      "Input stream read failed"
    }

    static var inputStreamLength: String {
      "Input stream length"
    }

    static var expectedLength: String {
      "Expected body content length"
    }

    static var encodedLength: String {
      "encodedLength"
    }
  }
}
