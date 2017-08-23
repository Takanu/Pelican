//
//  Debug.swift
//  Pelican
//
//  Created by Ido Constantine on 23/08/2017.
//

import Foundation

/**
Internally handles debug switches and prints for Pelican.  Provides a clean interface that categorises and sorts prints
while also ensuring the logs don't get included in any release builds.
*/
class PLog {
	
	static var switches: [DebugType:Bool] = [:]
	
	init() {
		for type in DebugType.cases() {
			PLog.switches[type] = false
		}
	}
	
	/**
	Enables the selected debug types for being printed
	*/
	func enableDebugTypes(types: DebugType...) {
		
		for type in types {
			PLog.switches[type] = true
		}
	}
	
	/**
	Turns on all available debug types for printing.
	*/
	func enableAllTypes() {
		
		PLog.switches.forEach({ PLog.switches[$0.key] = true })
	}
	
	/**
	Attempts to print the text based on what kind of debug it's associated with.
	Privately used from the convenience methods laid out in Debug+Prints.
	*/
	static internal func print(type: DebugType, level: DebugLevel, text: String) {
		
		#if PELICAN_DEBUG
		if PLog.switches[type] == true {
			print(text)
		}
		#endif
	}
}
