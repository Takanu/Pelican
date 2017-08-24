//
//  Debug+Enums.swift
//  Pelican
//
//  Created by Ido Constantine on 23/08/2017.
//

import Foundation

/**
Sets the log content categories, for when you wish to debug specific things.
*/
enum DebugType: String, CasedEnum {
	
	/// The update/upload/responce thread cycles
	case cycles
	/// Requests or responses to and from the Telegram API
	case apiMethods
	/// Logs relating to Telegram API types
	case apiTypes
	/// Session-related logs
	case session
	/// Logs relating to Session's modules
	case modules
	/// Logs relating to the Pelican type, and other types it controls.
	case pelican
	/// Logs not belonging to any particular category
	case other
	
	public func string() -> String {
		return rawValue
	}
}

/**
Provides the available levels of debugging available in PLog.
*/
enum DebugLevel: String, CasedEnum {
	
	case verbose
	case info
	case warning
	case error
	case severe
	
	public func string() -> String {
		return rawValue
	}
}
