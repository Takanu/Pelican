//
//  RouteController.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Manages all the routes available to a Session at any given time, and routes applicable user requests given to a Session
to any available and matching routes.  Also allows for the creation of Route Groups, that enable quick access and modification
to associated functionality.

Check out the `Route` type for the list of pre-built route types available.
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
	Clears all routes for all available user request types.
	*/
	public func clearAll() {
		collection.removeAll()
	}
	
}
