//
//  RoutePass.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation


/**
Allows any update handled by it to execute the action so long as it meets a specified update type.

Useful for when you wish to accept any kind of content input from the user and handle it inside the
given action.
*/
public class RoutePass: Route {
	
	/// The update types the update can potentially be in order for the action to be executed.
	public var updateTypes: [UpdateType] = []
	
	/**
	Initialises a Route that will allow any Update matching specific Update types to trigger an action.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter updateTypes: The types of updates the route can consider for triggering an action.
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(name: String = "", updateTypes: [UpdateType], action: @escaping (Update) -> (Bool)) {
		
		super.init(name: name, action: action)
		self.updateTypes = updateTypes
	}
	
	/**
	Initialises a Route that will allow any Update matching specific Update types to trigger an action.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter updateTypes: The types of updates the route can consider for triggering an action.
	- parameter action: The function to be executed if the Route is able to handle an incoming update.
	*/
	public init(name: String = "", updateTypes: [UpdateType], routes: Route...) {
		
		super.init(name: name, routes: routes)
		self.updateTypes = updateTypes
	}
	
	override public func handle(_ update: Update) -> Bool {
		
		if updateTypes.contains(update.type) == true {
			return passUpdate(update)
		}
		
		return false
	}
	
	override public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RoutePass {
			let otherRoute = route as! RoutePass
			
			// Check the type contents
			if self.updateTypes.count == otherRoute.updateTypes.count {
				
				for (i, type) in self.updateTypes.enumerated() {
					if type != otherRoute.updateTypes[i] { return false }
				}
				
				
			}
			
			// Check the base Route class
			return super.compare(otherRoute)
		}
		
		return false
	}
}
