
/// Import Vapor and get a droplet
import Vapor
import Pelican
import Foundation
import XCTest


class SetupTest: TestCase {
	
	func testPelicanSetup() throws {
		
		class TestBot: ChatSession {
			
			// Do your setup here, this is when the session gets created.
			override func postInit() {
				
				super.postInit()
				
				let start = RouteCommand(commands: "start") { update in
					if update.content == "" || update.from == nil { return false }
					
						_ = self.send.message("Hi there \(update.from!.firstName)!", markup: nil)
					
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
		pelican.cycleDebug = true
		
		// This defines what message types your bot can receive.
		pelican.allowedUpdates = [.message, .callbackQuery, .inlineQuery, .chosenInlineResult]
		pelican.timeout = 0
		
		// START IT UP!
		
		try config.addProvider(pelican)
		let drop = try Droplet(config)
		try drop.run()
	}
}
