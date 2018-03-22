//
//  ChatSessionRoute.swift
//
//  Created by Takanu Kyriako on 22/06/2017.
//
//

import Foundation



/**
The base class for filtering incoming updates either to functions or other routes for further filtering.

This base route class will handle all updates and perform no filtering, for pre-built Routes that do filter and
cover all common use-cases, see `RoutePass`, `RouteCommand`, `RouteListen` and `RouteManual`.
*/
open class Route {
	
	/// The name of the route instance.  This must be assigned on initialisation to allow for fetching nested routed in subscripts.
	public var name: String
	
	/// The action the route will execute if successful
	public var action: ( (Update) -> (Bool) )?
	
	/**
	Whether or not the route is enabled.  If disabled, the RouteController will ignore it when finding
	a route to pass an update to.
	*/
	public var enabled: Bool = true
	
	/// The routes to pass the request to next, if no action has been set or if the action fails.
	public var nextRoutes: [Route] = []
	
	/// The route to use if all other routes or actions are unable to handle the update.
	public var fallbackRoute: Route?
	
	/**
	Initialises a blank route that performs no filtering.
	*/
	public init(name: String, action: @escaping (Update) -> (Bool)) {
		self.name = name
		self.action = action
	}
	
	/**
	Initialises a blank route that performs no filtering.
	*/
	public init(name: String, routes: [Route]) {
		self.name = name
		self.nextRoutes = routes
	}
	
	/**
	Allows you to access routes that are linked to other routes
	*/
	public subscript(nameArray: [String]) -> Route? {
		for name in nameArray {
			for route in nextRoutes {
				
				if route.name == name {
					let nextNames = nameArray.dropFirst().filter { p in return true }
					
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
	
	/**
	Accepts an update for a route to try and handle, based on it's own criteria.
	- parameter update: The update to be handled.
	- returns: True if handled successfully, false if not.  Although the Route's action
	function might be called if the Route determines it can accept the update, this function
	can still return false if the action function returns as false.
	*/
	open func handle(_ update: Update) -> Bool {
		return passUpdate(update)
	}
	
	/**
	Allows a route to compare itself with another route of any type to see if they match.
	*/
	open func compare(_ route: Route) -> Bool {
		
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
	Adds the given routes to the `nextRoutes` array.  Convenience function.
	*/
	public func addRoutes(_ routes: Route...) {
		for route in routes {
			nextRoutes.append(route)
		}
	}
	
	/**
	Attempts to remove the given routes from the 'nextRoutes' array.
	*/
	public func removeRoutes(_ routes: Route...) {
		
		for route in routes {
			for (i, nextRoute) in nextRoutes.enumerated() {
				if route.compare(nextRoute) == true {
					nextRoutes.remove(at: i)
				}
			}
		}
	}
	
	/**
	Attempts to remove routes from the 'nextRoutes' array that match the given names.
	*/
	public func removeRoutes(_ names: String...) {
		
		for incomingName in names {
			if let routeIndex = nextRoutes.index(where: {$0.name == incomingName}) {
				nextRoutes.remove(at: routeIndex)
			}
		}
	}
	
	/**
	Empties the route of all actions, routes and fallbacks.
	*/
	open func clearAll() {
		self.action = nil
		self.nextRoutes = []
		self.fallbackRoute = nil
	}
	
	/**
	Closes the route system by ensuring all routes connected to it are cleared.
	Providing no strong reference cycles are present, this will help ensure the Session closes.
	*/
	open func close() {
		self.action = nil
		self.fallbackRoute = nil
		self.nextRoutes.forEach { T in T.close() }
		self.nextRoutes = []
	}
}










