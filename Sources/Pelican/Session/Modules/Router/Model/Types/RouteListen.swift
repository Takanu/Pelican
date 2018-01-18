//
//  RouteFilter.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor


/**
Used to specifically route specific update content like "Yes" or "$200" to actions.

- warning: Currently just supports string matching, Regex support will come later.
*/
public class RouteListen: Route {
	
	public var id: Int = 0
	public var name: String = ""
	public var action: (Update) -> (Bool)
	public var enabled: Bool = true
	
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
