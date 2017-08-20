//
//  ChatSessionRoute.swift
//
//  Created by Takanu Kyriako on 22/06/2017.
//
//

import Foundation
import Vapor


/**
Sets the framework for matching a single action to be used on a ChatSession RouteController (`session.routes`), to connect user
requests to bot functionality in a modular and contained way.

For pre-built Routes to cover all common use-cases, see `RoutePass`, `RouteCommand`, `RouteListen` and `RouteManual`.
*/
public protocol Route: class {
	
	/** 
	A unique identifier assigned to a Route when it's added to the RouteController, used to identify it for
	removal.
	*/
	var id: Int { get set }
	
	/// The action the route will execute if successful
	var action: (Update) -> (Bool) { get }
	
	/**
	Accepts an update for a route to try and handle, based on it's own criteria.
	- parameter update: The update to be handled.
	- returns: True if handled successfully, false if not.  Although the Route's action
	function might be called if the Route determines it can accept the update, this function
	can still return false if the action function returns as false.
	*/
	func handle(_ update: Update) -> Bool
	
	/**
	Allows a route to compare itself with another route of any type to see if they match.
	*/
	func compare(_ route: Route) -> Bool
}

extension Route {
	
	func setID(_ id: Int) {
		self.id = id
	}
}










