//
//  Debug.swift
//  Pelican
//
//  Created by Takanu Kyriako on 23/08/2017.
//

import Foundation


/**
Internally handles debug switches and prints for Pelican.  Provides a clean interface that categorises and sorts prints
while also ensuring the logs don't get included in any release builds.

If you want to see any logs before the Droplet is initialised, add "-DPELICAN_DEBUG" as a custom Swift compile flag.
*/
public class PLog {
	
	/// Use this to set entities that will be logged during testing.
	public static var displayLogTypes: [LogLevel] = []
	
	/// A callback to the console logger associated with the first droplet run.
//	static var console: LogProtocol?
	
	init() {}
	
	
	// Disabled until controls can be added to prevent unwanted levels being shown.
	/**
	Attempts to print the text based on what kind of debug it's associated with.
	Privately used from the convenience methods laid out in Debug+Prints.
	*/
	static internal func addPrint(level: LogLevel, text: String, file: String, function: String, line: Int) {
		
		if displayLogTypes.contains(level) == true {
			print("[\(function) : \(line)]: \(text)")
		}
	}
}
