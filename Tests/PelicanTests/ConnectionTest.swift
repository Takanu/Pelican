//
//  ConnectionTest.swift
//  PelicanTests
//
//  Created by Ido Constantine on 17/08/2017.
//

import XCTest
import Foundation
import Vapor
import Pelican

class TechnicalConnectionTypes: TestCase {
	
	/// The length of time a task is allowed to take before a timeout is triggered in the loop tests.
	var loopTimeout: Double = 5
	/// The number of times the defined operation will be repeated in the loop tests.
	var loopCount = 50
	/// The template to be operated with.
	var ghost = try! GhostPelican()
	
	override func setUp() {
		
		// Build a new template
		ghost = try! GhostPelican()
	}

	func testVaporRequestSingle() throws {
		XCTAssertNotNil(try ghost.drop.client.post(ghost.pelican.getAPIURL + "/getUpdates"))

	}
	
	func testVaporRequestLoop() throws {
		
		testLoop(loop: loopCount, timeout: loopTimeout, description: "Connect to the Telegram Bot API using Vapor.") {
			XCTAssertNotNil(try! self.ghost.drop.client.post(self.ghost.pelican.getAPIURL + "/getUpdates"))
		}
	}
	
	func testURLSessionRequestSingle() throws {
		
		// Build the session and request
		let expectation = self.expectation(description: "Build a JSON object from a URLSession Data Task.")
		var request = URLRequest(url: URL(string: self.ghost.pelican.getAPIURL + "/getUpdates")!)
		request.httpMethod = "GET"
		let session = URLSession.shared
		
		// Build the task
		session.dataTask(with: request) { data, response, error in
			
			if error != nil {
				XCTFail("The URL Session request returned with an error - \(error!)")
			}
				
			else {
				let json = try! JSON.init(bytes: data!.makeBytes())
				print(json)
				expectation.fulfill()
			}
		}.resume()
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testURLSessionRequestLoop() throws {
		
		testLoop(loop: loopCount, timeout: loopTimeout, description: "Connect to the Telegram Bot API using URLSession.") {
			
			// Build the session and request
			
			var request = URLRequest(url: URL(string: self.ghost.pelican.getAPIURL + "/getUpdates")!)
			request.httpMethod = "POST"
			let session = URLSession.shared
			
			// Build the task
			session.dataTask(with: request) { data, response, error in
				
				if error == nil {
					XCTFail("The URL Session request returned with an error - \(error!)")
				}
				
				else {
					let json = try! JSON.init(bytes: data!.makeBytes())
				}
			}.resume()
		}
	}
}
