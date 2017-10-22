//
//  RouteCommand.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Used to specifically route bot commands (such as /start and /hello@YourBot) to actions.  You can define multiple
commands, and as long as one of them matches the update content the action will be executed.

- warning: Will only work for Message-type Updates, handling any other update will always fail.
*/
public class RouteCommand: Route {
	
	public var id: Int = 0
	public var name: String = ""
	public var action: (Update) -> (Bool)
	public var enabled: Bool = true
	
	
	/// The commands to listen for in a message.  Only one has to be found in the set for the action to execute.
	public var commands: [String] = []
	
	/**
	Initialises a RouteCommand type, to link user message commands to bot actions.
	
	- parameter commands: The commands you wish the route to be bound to.  List them without a forward slash, and if
	multiple are being included, with commas in-between them (`"start, settings, shop"`).
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(commands: String, action: @escaping (Update) -> (Bool)) {
		
		self.action = action
		
		for command in commands.components(separatedBy: ",") {
			self.commands.append(command.replacingOccurrences(of: " ", with: ""))
		}
	}
	
	public func handle(_ update: Update) -> Bool {
		
		// Return if the update is not a message
		if update.type != .message { return false }
		
		let message = update.data as! Message
		
		if message.entities != nil {
			for entity in message.entities! {
				if entity.type == .botCommand {
					
					// Attempt to extract the command from the Message
					let commandString = entity.extract(fromMessage: message)
					if commandString != nil {
						
						var command = commandString!
						
						// Remove the bot name, and be left with just the command.
						if commandString!.contains("@") == true {
							
							command = command.components(separatedBy: "@")[0]
							command = command.replacingOccurrences(of: "/", with: "")
							//command.removeFirst()
						}
							
						else {
							//command.removeFirst()
							command = command.replacingOccurrences(of: "/", with: "")
						}
						
						// If the command is included in the given list, execute the action.
						if commands.contains(command) {
							return action(update)
						}
					}
				}
			}
		}
		
		return false
	}
	
	public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RouteCommand {
			let otherRoute = route as! RouteCommand
			
			// Check the ID
			if self.id != otherRoute.id { return false }
			
			// Check the command contents
			if self.commands.count == otherRoute.commands.count {
				
				for (i, type) in self.commands.enumerated() {
					if type != otherRoute.commands[i] { return false }
				}
				
				return true
			}
		}
		
		return false
	}
}
