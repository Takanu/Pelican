//
//  ChatSessionRoute.swift
//  party
//
//  Created by Takanu Kyriako on 22/06/2017.
//
//

import Foundation
import Vapor

/**
Manages all the routes available to a Session at any given time, and routes applicable user requests given to a Session
to any available and matching routes.

As generic
*/
public class RouteController {
	
	/**
	The currently active set of routes for the ChatSession.
	*/
	var collection: [Route] = []
	
	/**
	The active groups assigned to the route controller.
	*/
	var groups: [RouteGroup] = []
	
	/// The last ID assigned to a route.  Unlike Builder IDs, these are assigned sequentially to prevent an overlap.
	var lastID: Int = 0
	
	init() { }
	
	/**
	Attempts to find and execute a route for the given user request, should only ever be accessed by ChatSession.
	*/
	func handle(update: Update) -> Bool {
		
		for route in collection {
			if route.handle(update) == true { return true }
		}
		
		for group in groups {
			if group.handle(update) == true { return true }
		}
		
		return false
	}
	
	
	/** 
	Adds a route to the session, enabling it to be used to receive user requests.  If the session already has a route that 
	matches the one provided in type and filter, it will be overwritten.
	- parameter routes: The routes to be added to the controller.
	*/
	public func add(_ routes: Route...) {
		
		for route in routes {
			
			// If the route ID is 0, we need to give it a unique one.
			if route.id == 0 {
				lastID += 1
				route.setID(lastID)
			}
			
			self.collection.append(route)
		}
	}
	
	/**
	Adds a group of routes to the session, enabling them to be used to receive user requests. Adding a group allows you to enable and
	disable the routes it owns from being used by calling `setGroup(name:enabled:)`, as well as removing them using `removeGroup(name:)`.
	
	To avoid unexpected results, do not add a Route using `add(_:)` as well as this function, or otherwise it's action may be executed twice.
	
	- returns: True if the group was successfully created, false if not. If you try defining a group with a name that's identical to one that 
	the controller already has, it will not be created.
	*/
	public func addGroup(name: String, routes: Route...) -> Bool {
		
		// If a group with the same name exists, remove it.
		if groups.first(where: { $0.name == name }) != nil { return false }
		
		// Assign IDs here beforehand
		for route in routes {
			
			// If the route ID is 0, we need to give it a unique one.
			if route.id == 0 {
				lastID += 1
				route.setID(lastID)
			}
		}
		
		let group = RouteGroup(name: name, routes: routes)
		groups.append(group)
		
		return true
	}
	
	/**
	Sets the status of a group to either enabled or disabled.
	*/
	public func setGroupStatus(name: String, enabled: Bool) {
		
		if let group = groups.first(where: { $0.name == name }) {
			group.enabled = enabled
		}
	}
	
	/**
	Gets the status of a group, using it's name.
	*/
	public func getGroupStatus(name: String) -> Bool? {
		
		if let group = groups.first(where: { $0.name == name }) {
			return group.enabled
		}
		
		return nil
	}
	
	/**
	Removes a Route from the stack if it matches the one provided.
	*/
	public func remove(_ route: Route) {
		
		for (i, otherRoute) in collection.enumerated() {
			if otherRoute.compare(route) == true {
				
				collection.remove(at: i)
				return
			}
		}
	}
	
	/**
	Removes a RouteGroup from the stack if the name provided matches one 
	currently held by the controller.
	*/
	public func removeGroup(name: String) -> Bool {
		
		if let index = groups.index(where: {$0.name == name} ) {
			groups.remove(at: index)
			return true
		}
		
		return false
	}
	
	/**
	Clears all routes for all available user request types.
	*/
	public func clearAll() {
		collection.removeAll()
	}
	
}

/**
Defines a collection of routes that can be enabled and disabled, without having to remove it from the controller.
*/
class RouteGroup {
	
	// Core Data
	var name: String
	var collection: [Route] = []
	
	// State
	public var enabled: Bool = true
	
	init(name: String, routes: [Route]) {
		
		self.name = name
		self.collection = routes
	}
	
	/**
	Attempts to find and execute a route for the given user request, should only ever be accessed by ChatSession.
	*/
	func handle(_ update: Update) -> Bool {
		
		if enabled == false { return false }
		
		for route in collection {
			if route.handle(update) == true { return true }
		}
		
		return false
	}
	
}


/**
Sets the framework for matching a single action to be used on a ChatSession RouteController (`session.routes`), to connect user
requests to bot functionality in a modular and contained way.

For pre-built Routes to cover all common use-cases, see `RoutePass`, `RouteCommand`, `RouteListen` and `RouteManual`.
*/
public protocol Route: class {
	
	/** 
	A unique identifier assigned to a Route when it's added to the RouteController, used to identify it for
	removal.
	*/
	var id: Int { get set }
	
	/// The action the route will execute if successful
	var action: (Update) -> (Bool) { get }
	
	/**
	Accepts an update for a route to try and handle, based on it's own criteria.
	- returns: True if handled successfully, false if not.  Although the Route's action
	function might be called, it can still return false if the action function returns as false.
	*/
	func handle(_ update: Update) -> Bool
	
	/**
	Allows a route to compare itself with another route of any type to see if they match.
	*/
	func compare(_ route: Route) -> Bool
}

extension Route {
	
	func setID(_ id: Int) {
		self.id = id
	}
}




/**
Allows any update handled by it to execute the action so long as it meets a specified update type.
Useful for when you wish to accept any kind of content input from the user.
*/
public class RoutePass: Route {
	
	public var id: Int = 0
	public var action: (Update) -> (Bool)
	
	/// The update types the update can potentially be in order for the action to be executed.
	public var updateTypes: [UpdateType] = []
	
	/**
	Initialises a Route that will allow any Update matching specific Update types to trigger an action.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter updateTypes: The types of updates the route can consider for triggering an action.
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(updateTypes: [UpdateType], action: @escaping (Update) -> (Bool)) {
		
		self.action = action
		self.updateTypes = updateTypes
	}
	
	public func handle(_ update: Update) -> Bool {
		
		if updateTypes.contains(update.type) == true {
			return action(update)
		}
		
		return false
	}
	
	public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RoutePass {
			let otherRoute = route as! RoutePass
			
			// Check the ID
			if self.id != otherRoute.id { return false }
			
			// Check the type contents
			if self.updateTypes.count == otherRoute.updateTypes.count {
				
				for (i, type) in self.updateTypes.enumerated() {
					if type != otherRoute.updateTypes[i] { return false }
				}
				
				return true
			}
		}
		
		return false
	}
}

/**
Used to specifically route bot commands (such as /start and /hello@YourBot) to actions.  You can define multiple
commands, and as long as one of them matches the update content the action will be executed.
*/
public class RouteCommand: Route {
	
	public var id: Int = 0
	public var action: (Update) -> (Bool)
	
	
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
							command.removeFirst()
						}
						
						else {
							command.removeFirst()
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

/**
Used to specifically route bot commands (such as /start and /hello@YourBot) to actions.  You can define multiple
commands, and as long as one of them matches the update content the action will be executed.

- warning: Currently just supports string matching, Regex support will come later.
*/
public class RouteListen: Route {
	
	public var id: Int = 0
	public var action: (Update) -> (Bool)
	
	/** 
	The pattern that the update content is compared against, to decide whether or not to use it.
	Leave it blank if the route is dynamic and wishes to receive any already unclaimed responses.
	*/
	public var pattern: String = ""
	
	/// The type of user request the route targets.
	private var type: UpdateType
	
	/// Retrieves the route type, that determines what kind of user responses it is targeting.
	public var getType: UpdateType { return type }
	
	/**
	Initialises a route that listens out for specific pieces of text in update content.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter pattern: The text or RegEx request to search for in the contents of an update.
	- parameter type: The types of updates the route can consider for triggering an action.
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(pattern: String, type: UpdateType, action: @escaping (Update) -> (Bool)) {
		
		self.type = type
		self.action = action
		self.pattern = pattern
	}
	
	public func handle(_ update: Update) -> Bool {
		
		// If the types match, check the filter
		if update.matches(pattern, types: [type.string()]) == true {
			
			// If we made it, execute the action
			return action(update)
			
		}
		
		return false
	}
	
	public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RouteListen {
			let otherRoute = route as! RouteListen
			
			// Check the properties
			if self.id != otherRoute.id { return false }
			if self.pattern != otherRoute.pattern { return false }
			if self.type != otherRoute.type { return false }
			
			return true
		}
		
		return false
	}
}

/**
Lets you define your own routing function for incoming updates.
*/
public class RouteManual: Route {
	
	public var id: Int = 0
	public var action: (Update) -> (Bool)
	
	/// The commands to listen for in a message.  Only one has to be found in the set for the action to execute.
	public var handler: (Update) -> (Bool)
	
	/**
	Initialises a route with a manually defined handler function to check whether an Update can trigger a Route action.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter handler: The custom handler to use to define whether an Update can trigger a Route action.
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(handler: @escaping (Update) -> (Bool), action: @escaping (Update) -> (Bool)) {
		
		self.action = action
		self.handler = handler
	}
	
	public func handle(_ update: Update) -> Bool {
		return handler(update)
	}
	
	public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RouteManual {
			let otherRoute = route as! RouteManual
			
			// Check the properties
			if self.id != otherRoute.id { return false }
			
			return true
		}
		
		return false
	}
}

