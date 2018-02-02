//
//  ChatSessionRoute.swift
//
//  Created by Takanu Kyriako on 22/06/2017.
//
//

import Foundation
import Vapor


/**
The base class for filtering incoming updates either to functions or other routes for further filtering.

This base route class will handle all updates and perform no filtering, for pre-built Routes that do filter and cover all common use-cases, see `RoutePass`, `RouteCommand`, `RouteListen` and `RouteManual`.
*/
public class Route {
	
	/// The name of the route instance.  This must be assigned on initialisation to allow for fetching nested routed in subscripts.
	var name: String
	
	/// The action the route will execute if successful
	var action: ( (Update) -> (Bool) )?
	
	/**
	Whether or not the route is enabled.  If disabled, the RouteController will ignore it when finding
	a route to pass an update to.
	*/
	var enabled: Bool = true
	
	/// The routes to pass the request to next, if no action has been set or if the action fails.
	var nextRoutes: [Route] = []
	
	/// The route to use if all other routes or actions are unable to handle the update.
	var fallbackRoute: Route?
	
	
	
	/**
	Allows you to access routes that are linked to other routes
	*/
	subscript(names: [String]) -> Route? {
		get {
			for name in names {
				for route in nextRoutes {
					
					if route.name == name {
						let nextNames = names.dropFirst().array
						
						if nextNames.count == 0 {
							return route
						} else {
							return route[nextNames]
						}
					}
				}
				
			}
			
			return nil
		}
	}
	
	
	/**
	Initialises a blank route that performs no filtering.
	*/
	init(name: String, action: @escaping (Update) -> (Bool)) {
		self.name = name
		self.action = action
	}
	
	/**
	Initialises a blank route that performs no filtering.
	*/
	init(name: String, routes: [Route]) {
		self.name = name
		self.nextRoutes = routes
	}
	
	/**
	Accepts an update for a route to try and handle, based on it's own criteria.
	- parameter update: The update to be handled.
	- returns: True if handled successfully, false if not.  Although the Route's action
	function might be called if the Route determines it can accept the update, this function
	can still return false if the action function returns as false.
	*/
	public func handle(_ update: Update) -> Bool {
		return passUpdate(update)
	}
	
	/**
	Allows a route to compare itself with another route of any type to see if they match.
	*/
	public func compare(_ route: Route) -> Bool {
		
		if name != route.name { return false }
		if enabled != route.enabled { return false }
		
		if nextRoutes.count != route.nextRoutes.count { return false }
		for (i, leftNextRoute) in nextRoutes.enumerated() {
			let rightNextRoute = route.nextRoutes[i]
			
			if leftNextRoute.compare(rightNextRoute) == false { return false }
		}
		
		return true
		
	}
	
	
	/**
	When a handler function succeeds, this should always be called to decide where the update goes next.
	*/
	public func passUpdate(_ update: Update) -> Bool {
		
		// Attempt to use an assigned action
		if action != nil {
			if action!(update) == true { return true }
		}
		
		// Attempt to find a route that will successfully handle the update.
		for route in nextRoutes {
			if route.enabled == true {
				if route.handle(update) == true { return true }
			}
		}
		
		// Attempt to use a fallback route
		if fallbackRoute != nil {
			if fallbackRoute!.enabled == true {
				if fallbackRoute!.handle(update) == true { return true }
			}
		}
		
		// Otherwise return in FAILURE.
		return false
		
	}
	
	/**
	Empties the route of all actions, routes and fallbacks.
	*/
	public func clearAll() {
		self.action = nil
		self.nextRoutes = []
		self.fallbackRoute = nil
	}
	
	/**
	Closes the route system by ensuring all routes connected to it are cleared.
	Providing no strong reference cycles are present, this will help ensure the Session closes.
	*/
	public func close() {
		self.action = nil
		self.fallbackRoute = nil
		self.nextRoutes.forEach { T in T.close() }
		self.nextRoutes = []
	}
}










