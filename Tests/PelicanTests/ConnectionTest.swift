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

class TestConnectionLoopConsistency: TestCase {
	
	var loopTimeout: Double = 5
	var loopCount = 50
	
	func testVaporRequestSingle() throws {
		
		let template = try generateTemplate()!
		XCTAssertNotNil(try template.drop.client.post(template.pelican.getAPIURL))

	}
	
	func testVaporRequestLoop() throws {
		
		let template = try generateTemplate()!
		
		testLoop(loop: loopCount, timeout: loopTimeout, description: "Connect to the Telegram Bot API using Vapor.") {
			
			guard let _ = try? template.drop.client.post(template.pelican.getAPIURL) else {
				XCTFail("Failed to receive a response.")
				return
			}
		}
	}
	
	func testURLSessionRequestLoop() throws {
		
		let template = try generateTemplate()!
		
		testLoop(loop: loopCount, timeout: loopTimeout, description: "Connect to the Telegram Bot API using URLSession.") {
			
			// Build the session and request
			var request = URLRequest(url: URL(string: template.pelican.getAPIURL)!)
			request.httpMethod = "POST"
			let session = URLSession.shared
			
			// Commence the task
			session.dataTask(with: request).resume()
		}
	}
}
