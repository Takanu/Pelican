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
class PLog {
	
	/// A callback to the console logger associated with the first droplet run.
//	static var console: LogProtocol?
	
	init() {}
	
	/**
	Attempts to print the text based on what kind of debug it's associated with.
	Privately used from the convenience methods laid out in Debug+Prints.
	*/
	static internal func addPrint(level: LogLevel, text: String, file: String, function: String, line: Int) {
		print("\(function) : \(line) ===\n\(text)")

//			console!.log(level, message: text, file: file, function: function, line: line)
			// *shrug*
	}
}
