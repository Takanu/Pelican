//
//  Pelican+Errors.swift
//  Pelican
//
//  Created by Ido Constantine on 23/01/2018.
//

import Foundation

/**
Errors relating to Pelican setup.
*/
enum PError_Codable: String, Error {
	case InlineResultAnyDecodable = "InlineResultAny was unable to be decoded, InlineResultAny is only a wrapper and should not be treated as an entity to encode and decode to."
}
