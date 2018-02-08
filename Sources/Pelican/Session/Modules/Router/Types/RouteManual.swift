//
//  RouteManual.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Lets you define your own routing function for incoming updates.
*/
public class RouteManual: Route {
	
	/// The commands to listen for in a message.  Only one has to be found in the set for the action to execute.
	public var handler: (Update) -> (Bool)
	
	/**
	Initialises a route with a manually defined handler function to check whether a given update can trigger another function.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter handler: The custom handler to use to define whether an Update can trigger a Route action.  Return true if the update should be used by the route, false if not.
	- parameter action: The function to be executed if the Route is able to handle an incoming update, verified by the handler function.
	*/
	public init(name: String = "", handler: @escaping (Update) -> (Bool), action: @escaping (Update) -> (Bool)) {
		
		self.handler = handler
		super.init(name: name, action: action)
	}
	
	/**
	Initialises a route with a manually defined handler function to check whether a given update can trigger another function.
	- parameter name: The name of the route.  This is used to check for equatibility with other routes, so ensure
	you create unique names for routes you want to be considered separate entities.
	- parameter handler: The custom handler to use to define whether an Update can trigger a Route action.  Return true if the update should be used by the route, false if not.
	- parameter routes: The routes that an update will be propagated to if the handler function returns true.
	*/
	public init(name: String = "", handler: @escaping (Update) -> (Bool), routes: Route...) {
		
		self.handler = handler
		super.init(name: name, routes: routes)
	}
	
	override public func handle(_ update: Update) -> Bool {
		
		let result = handler(update)
		
		if result == true {
			return passUpdate(update)
		} else {
			return false
		}

	}
	
	override public func compare(_ route: Route) -> Bool {
		
		// Check the types match
		if route is RouteManual {
			let otherRoute = route as! RouteManual
			return super.compare(otherRoute)
		}
		
		return false
	}
}
