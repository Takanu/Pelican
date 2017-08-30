//
//  Type+Error.swift
//  Pelican
//
//  Created by Ido Constantine on 29/08/2017.
//

import Foundation

// Errors related to update processing.
enum TypeError: String, Error {
	case ExtractFailed = "The extraction failed."
}

enum MarkupError: String, Error {
	case ExceededByteLimit = "The data assigned to this key exceeds the maximum byte limit."
}
