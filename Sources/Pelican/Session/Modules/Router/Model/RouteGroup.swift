//
//  RouteGroup.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

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
			if route.enabled == false { continue }
			if route.handle(update) == true { return true }
		}
		
		return false
	}
	
}
