//
//  Debug+Prints.swift
//  Pelican
//
//  Created by Ido Constantine on 23/08/2017.
//

import Foundation

extension PLog {
	
	/**
	Attempts to print a log at the verbose level, with the included type and text.
	*/
	static func verbose(_ type: DebugType, text: String) {
		PLog.print(type: type, level: .verbose, text: text)
	}
	
	/**
	Attempts to print a log at the info level, with the included type and text.
	*/
	static func info(_ type: DebugType, text: String) {
		PLog.print(type: type, level: .info, text: text)
	}
	
	/**
	Attempts to print a log at the warning level, with the included type and text.
	*/
	static func warning(_ type: DebugType, text: String) {
		PLog.print(type: type, level: .warning, text: text)
	}
	
	/**
	Attempts to print a log at the error level, with the included type and text.
	*/
	static func error(_ type: DebugType, text: String) {
		PLog.print(type: type, level: .error, text: text)
	}
	
	/**
	Attempts to print a log at the severe level, with the included type and text.
	*/
	static func severe(_ type: DebugType, text: String) {
		PLog.print(type: type, level: .severe, text: text)
	}
	
}
