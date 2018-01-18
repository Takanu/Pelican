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
	
	public var id: Int = 0
	public var name: String = ""
	public var action: (Update) -> (Bool)
	public var enabled: Bool = true
	
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
