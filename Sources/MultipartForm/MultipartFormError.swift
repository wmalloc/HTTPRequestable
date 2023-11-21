//
//  MultipartFormError.swift
//
//
//  Created by Waqar Malik on 1/17/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import Foundation

public enum MultipartFormError: LocalizedError, Sendable {
	case badURL(URL)
	case invalidFilename(URL)
	case fileNotFound(URL, Error?)
	case fileAlreadyExists(URL)
	case accessDenied(URL)
	case fileIsDirectory(URL)
	case fileSizeNotAvailable(URL)
	case streamCreation(URL)
	case outputStreamWriteFailed(Error)
	case inputStreamReadFailed(Error)
	case inputStreamLength(String)

	public var errorDescription: String? {
		switch self {
		case .badURL(let url):
			return "multipart_error_invalid_url".localized() + " " + url.absoluteString
		case .invalidFilename(let url):
			return "multipart_error_invalid_filename".localized() + " " + url.absoluteString
		case .fileNotFound(let url, let error):
			return "multipart_error_file_notfound".localized() + " " + url.absoluteString + " " + (error?.localizedDescription ?? "")
		case .fileAlreadyExists(let url):
			return "multipart_error_file_already_exists".localized() + " " + url.absoluteString
		case .accessDenied(let url):
			return "multipart_error_access_denined".localized() + " " + url.absoluteString
		case .fileIsDirectory(let url):
			return "multipart_error_file_is_directory".localized() + " " + url.absoluteString
		case .fileSizeNotAvailable(let url):
			return "multipart_error_file_size_not_available".localized() + " " + url.absoluteString
		case .streamCreation(let url):
			return "multipart_error_stream_creation".localized() + " " + url.absoluteString
		case .outputStreamWriteFailed(let error):
			return "multipart_error_output_stream_write_failed".localized() + " " + error.localizedDescription
		case .inputStreamReadFailed(let error):
			return "multipart_error_input_stream_read_failed".localized() + " " + error.localizedDescription
		case .inputStreamLength(let message):
			return "multipart_error_input_stream_length".localized() + " " + message
		}
	}
}
