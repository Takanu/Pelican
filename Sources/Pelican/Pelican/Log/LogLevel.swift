//
//  LogLevel.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

/**
???
*/
enum LogLevel: String, CasedEnum {
	
	/// The update/upload/responce thread cycles
	case verbose
	
	/// Requests or responses to and from the Telegram API
	case info
	
	/// Logs relating to Telegram API types
	case warning
	
	/// Session-related logs
	case error
	
	/// Logs relating to Session's modules
	case fatal
	
	public func string() -> String {
		return rawValue
	}
}
