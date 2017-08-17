//
//  PelicanTest.swift
//  PelicanTests
//
//  Created by Ido Constantine on 17/08/2017.
//

import XCTest
import Foundation
import Vapor
import Pelican

enum TestTemplateError: String, Error {
	case NoToken = "The token could not be found."
}

// Used to provide common functions between test cases.
class TestCase: XCTestCase {
	
	/// Creates a basic Pelican and Droplet object.
	func generateTemplate() throws -> (drop: Droplet, pelican: Pelican, config: Config, token: String)? {
		
		// Make sure you set up Pelican manually so you can assign it variables.
		let config = try! Config()
		let pelican = try! Pelican(config: config)
		
		guard let token = config["pelican", "token"]?.string else {
			throw TestTemplateError.NoToken
		}
		
		pelican.setPoll(interval: 1)
		pelican.cycleDebug = true
		
		try config.addProvider(pelican)
		let drop = try Droplet(config)
		
		return (drop, pelican, config, token)
	}
	
	
	/// Repeats a given task multiple times, to see if it fails to complete it or if other errors are asserted.
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
			waitForExpectations(timeout: timeout) { error in
				
				// If we received an error as a result of the expectation not being fulfilled, assert an error and escape.
				if error != nil {
					XCTFail("Took too long to complete the task.")
					escape = true
					return
				}
			}
			
			if escape == true { break }
		}
	}
	
}
