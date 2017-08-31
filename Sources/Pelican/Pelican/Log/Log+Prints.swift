//
//  Debug+Prints.swift
//  Pelican
//
//  Created by Takanu Kyriako on 23/08/2017.
//

import Foundation

extension PLog {
	
	/**
	Attempts to print a log at the verbose level, with the included type and text.
	Also automatically includes the file, function and line the function is called from.
	*/
	static func verbose(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
		PLog.addPrint(level: .verbose, text: text, file: file, function: function, line: line)
	}
	
	/**
	Attempts to print a log at the info level, with the included type and text.
	Also automatically includes the file, function and line the function is called from.
	*/
	static func info(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
		PLog.addPrint(level: .info, text: text, file: file, function: function, line: line)
	}
	
	/**
	Attempts to print a log at the warning level, with the included type and text.
	Also automatically includes the file, function and line the function is called from.
	*/
	static func warning(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
		PLog.addPrint(level: .warning, text: text, file: file, function: function, line: line)
	}
	
	/**
	Attempts to print a log at the error level, with the included type and text.
	Also automatically includes the file, function and line the function is called from.
	*/
	static func error(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
		PLog.addPrint(level: .error, text: text, file: file, function: function, line: line)
	}
	
	/**
	Attempts to print a log at the severe level, with the included type and text.
	Also automatically includes the file, function and line the function is called from.
	*/
	static func fatal(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
		PLog.addPrint(level: .fatal, text: text, file: file, function: function, line: line)
	}
	
}
