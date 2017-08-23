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
	
	case updateCycle
	case requests
	case session
	case modules
	case pelican
	
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
