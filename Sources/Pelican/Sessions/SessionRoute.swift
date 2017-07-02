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
public class RouteController<UpdateType: UpdateCollection, Session, UpdateObject: Update> {
	
	/**
	The currently active set of routes for the ChatSession.
	- warning: It's recommended to just use the provided functions for editing and removing routes, only use this if
	you need something custom 👌.
	*/
	public var collection: [UpdateType : [Route<UpdateType, Session, UpdateObject>]]
	
	
	init() {
		collection = [:]
		
		for type in UpdateType.cases() {
			collection[type] = []
		}
	}
	
	/**
	Attempts to find and execute a route for the given user request, should only ever be accessed by ChatSession.
	*/
	func routeRequest(update: UpdateObject, type: UpdateType, session: Session) -> Bool {
		
		var handled = false
		
			
		// Run through all available routes
		for route in collection[type]!	{
			
			// Extract and execute the contained action.
			let action = route.getAction
			
			// If the types match, check the filter
			if update.matches(route.pattern, types: [type.string()]) == true {
				
				// If we made it, execute the action
				handled = action(session, update)
				
			}
			
			// If it's been handled by the route, return true
			if handled == true {
				return handled
			}
		}
		
		// Return the result (100% false at this point)
		return handled
	}
	
	
	/** 
	Adds a route to the session, enabling it to be used to receive user requests.  If the session already has a route that 
	matches the one provided in type and filter, it will be overwritten.
	- parameter routes: The routes to be added to the controller.
	*/
	public func add(_ routes: Route<UpdateType, Session, UpdateObject>...) {
		
		for route in routes {
			var routeArray = collection[route.getType]!
			
			if route.pattern != "" {
				
				// If an existing route already exists with the same criteria, remove it.
				if routeArray.first(where: { $0.pattern == route.pattern } ) != nil {
					
					let index = routeArray.index(where: {$0.pattern == route.pattern } )!
					routeArray.remove(at: index)
				}
				
				routeArray.insert(route, at: 0)
			}
				
			else {
				routeArray.append(route)
			}
			
			collection[route.getType] = routeArray
		}
	}
	
	/**
	Adds a single route to the session based on the components that make up a route for this controller, enabling it to be used to receive user requests.  
	If the session already has a route that matches the one provided in type and filter, it will be overwritten.
	- parameter routes: The routes to be added to the controller.
	*/
	public func add(_ pattern: String, type: UpdateType, action: @escaping (Session, UpdateObject) -> (Bool) ) {
		
		let route = Route.init(pattern, type: type, action: action)
		
		var routeArray = collection[route.getType]!
		
		if route.pattern != "" {
			
			// If an existing route already exists with the same criteria, remove it.
			if routeArray.first(where: { $0.pattern == route.pattern } ) != nil {
				
				let index = routeArray.index(where: {$0.pattern == route.pattern } )!
				routeArray.remove(at: index)
			}
			
			routeArray.insert(route, at: 0)
		}
			
		else {
			routeArray.append(route)
		}
		
		collection[route.getType] = routeArray
	}

	
	/**
	Removes a route based on a given route type and filter name.
	- parameter type: The request target of the route you wish to remove.
	- parameter filter: The filter of the route to be removed.
	- returns: True if a route matched the given criteria and was removed, false if not.
	*/
	public func remove(type: UpdateType, filter: String) -> Bool {
		
		var routeSet = collection[type]!
		
		for route in routeSet {
			
			if let index = routeSet.index(where: {$0.pattern == filter} ) {
				routeSet.remove(at: index)
				collection[type]! = routeSet
				return true
			}
		}
		
		return false
	}
	
	/**
	Clears all routes of a given request target from the session.
	- parameter type: The request target you wish to clear.
	*/
	public func clear(type: UpdateType) {
		collection[type] = []
	}
	
	/**
	Clears all routes of a given type that have no defined filter.  Useful if you have one or two routes
	that act as a default request collector, that due to the current state of the bot require removal.
	*/
	public func clearUnfiltered(type: UpdateType) {
		
		var newRouteSet: [Route<UpdateType, Session, UpdateObject>] = []
		
		for route in collection[type]! {
			
			if route.pattern != "" {
				newRouteSet.append(route)
			}
		}
		
		collection[type]! = newRouteSet
	}
	
	
	/**
	Clears all routes for all available user request types.
	*/
	public func clearAll() {
		collection.removeAll()
	}
	
}



/**
Defines a single action to be used on a ChatSession RouteController (`session.routes`), to connect user 
requests to bot functionality in a modular and contained way.
*/
public class Route<UpdateType: UpdateCollection, Session, UpdateObject: Update> {
	
	/** 
	The route that user responses are compared against, to decide whether or not to use it.
	Leave it blank if the route is dynamic and wishes to receive any already unclaimed responses.
	*/
	public var pattern: String = ""
	
	/// The type of user request the route targets.
	private var type: UpdateType
	
	/// Retrieves the route type, that determines what kind of user responses it is targeting.
	public var getType: UpdateType { return type }
	
	// Privately held actions.  Each route can only have one action, and
	private var action: (Session, UpdateObject) -> (Bool)
	public var getAction: (Session, UpdateObject) -> (Bool) { return action }
	
	/**
	Initialises a route with a Message-type action and "Message" user response type.
	*/
	public init(_ pattern: String, type: UpdateType, action: @escaping (Session, UpdateObject) -> (Bool) ) {
		self.pattern = pattern
		self.type = type
		self.action = action
	}
}

