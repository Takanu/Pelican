//
//  PelicanTest.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 17/08/2017.
//

import XCTest
import Foundation
import Vapor
import Pelican

enum TestTemplateError: String, Error {
	case NoToken = "The token could not be found."
}

class GhostPelican {
	var drop: Droplet
	var pelican: Pelican
	var config: Config
	var token: String
	
	init() throws {
		
		// Make sure you set up Pelican manually so you can assign it variables.
		config = try Config()
		pelican = try Pelican(config: config)
		
		token = (config["pelican", "token"]?.string!)!
		
		pelican.setPoll(interval: 1)
		pelican.cycleDebug = true
		
		try config.addProvider(pelican)
		drop = try Droplet(config)
	}
}

// Used to provide common functions between test cases.
class TestCase: XCTestCase {
	
	/**
	Repeats a given task multiple times, to see if it fails to complete it or if other errors are asserted.
	The function will also report back assertions with the number of times the operation was successfully executed beforehand.
	*/
	func testLoop(loop: Int, timeout: Double, description: String, task: @escaping () -> Void) {
		
		var i = 0
		
		for _ in 0..<loop {
			
			// Setup escapes, expectations, the Dispatch queue and the operation to be performed,
			// wrapped around the expectation
			var escape = false
			let expectation = self.expectation(description: description)
			let queue = DispatchQueue(label: "TG-Updates", qos: .userInteractive, target: nil)
	
			let operation = DispatchWorkItem(qos: .userInteractive, flags: .enforceQoS) {
				
				task()
				i += 1
				expectation.fulfill()
			}
			
			// Perform the operation and set-up the expectation
			queue.asyncAfter(deadline: .init(secondsFromNow: 1), execute: operation)
			waitForExpectations(timeout: timeout + 1) { error in
				
				// If we received an error as a result of the expectation not being fulfilled, assert an error and escape.
				if error != nil {
					XCTFail("Took too long to complete the task.  Failed after \(i) operations.")
					escape = true
					return
				}
			}
			
			if escape == true { break }
		}
	}
	
}
