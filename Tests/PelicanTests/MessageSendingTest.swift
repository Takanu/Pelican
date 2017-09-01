//
//  TestMessageSending.swift
//  PelicanTests
//
//  Created by Ido Constantine on 31/08/2017.
//

import XCTest
import Pelican
import Vapor

class TestMessageSending: XCTestCase {

	
	override func setUp() {
		
	}
    
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testExample() {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct results.
		
		func testPelicanSetup() throws {
			
			class TestBot: ChatSession {
				
				// Do your setup here, this is when the session gets created.
				override func postInit() {
					
					super.postInit()
					
					let start = RouteCommand(commands: "start") { update in
						if update.content == "" || update.from == nil { return false }
						
						let audio = Audio(url: "ferriswheel.mp3")
						self.send.file(audio, caption: "Hey check out this kool tuun.", markup: nil)
						
						return true
					}
					
					routes.add(start)
				}
			}
			
			// Make sure you set up Pelican manually so you can assign it variables.
			let config = try! Config()
			let pelican = try! Pelican(config: config)
			
			// Add Builder
			pelican.addBuilder(SessionBuilder(spawner: Spawn.perChatID(updateType: [.message], chatType: [.private]), idType: .chat, session: TestBot.self, setup: nil) )
			
			pelican.setPoll(interval: 1)
			
			// This defines what message types your bot can receive.
			pelican.allowedUpdates = [.message, .callbackQuery, .inlineQuery, .chosenInlineResult]
			pelican.timeout = 0
			
			// START IT UP!
			try config.addProvider(pelican)
			let drop = try Droplet(config)
			try drop.run()
		}
	}

}
