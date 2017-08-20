//
//  RoutePass.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Allows any update handled by it to execute the action so long as it meets a specified update type.

Useful for when you wish to accept any kind of content input from the user and handle it inside the
given action.
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
