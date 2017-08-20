//
//  RouteController+Groups.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

extension RouteController {
	/**
	Adds a group of routes to the session, enabling them to be used to receive user requests. Adding a group allows you to enable and
	disable the routes it owns from being used by calling `setGroup(name:enabled:)`, as well as removing them using `removeGroup(name:)`.
	
	To avoid unexpected results, do not add a Route using `add(_:)` as well as this function, or otherwise it's action may be executed twice.
	
	- returns: True if the group was successfully created, false if not. If you try defining a group with a name that's identical to one that
	the controller already has, it will not be created.
	*/
	public func addGroup(name: String, routes: Route...) -> Bool {
		
		// If a group with the same name exists, remove it.
		if groups.first(where: { $0.name == name }) != nil { return false }
		
		// Assign IDs here beforehand
		for route in routes {
			
			// If the route ID is 0, we need to give it a unique one.
			if route.id == 0 {
				lastID += 1
				route.setID(lastID)
			}
		}
		
		let group = RouteGroup(name: name, routes: routes)
		groups.append(group)
		
		return true
	}
	
	/**
	Sets the status of a group to either enabled or disabled.
	*/
	public func setGroupStatus(name: String, enabled: Bool) {
		
		if let group = groups.first(where: { $0.name == name }) {
			group.enabled = enabled
		}
	}
	
	/**
	Gets the status of a group, using it's name.
	*/
	public func getGroupStatus(name: String) -> Bool? {
		
		if let group = groups.first(where: { $0.name == name }) {
			return group.enabled
		}
		
		return nil
	}
	
	/**
	Removes a RouteGroup from the stack if the name provided matches one
	currently held by the controller.
	*/
	public func removeGroup(name: String) -> Bool {
		
		if let index = groups.index(where: {$0.name == name} ) {
			groups.remove(at: index)
			return true
		}
		
		return false
	}
}
