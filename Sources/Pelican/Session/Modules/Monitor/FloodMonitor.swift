//
//  Flood.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation


/**
Used for monitoring and controlling updates sent to a session by a user.
*/
public class FloodMonitor {
	
	/// The currently active set of limits.
	var limits: [FloodLimit] = []
	
	init() { }
	
	/**
	Adds a new flood monitor to the class.  If the criteria for the flood monitor you're attempting to add match a
	monitor thats already being used, a new monitor will not be created.
	*/
	public func add(type: [UpdateType], hits: Int, duration: Duration, action: @escaping () -> ()) {
		
		let limit = FloodLimit(type: type, hits: hits, duration: duration, action: action)
		if limits.contains(limit) { return }
		
		limits.append(limit)
		
	}
	
	/**
	Passes the update to all available monitors.
	*/
	public func handle(_ update: Update) {
		
		limits.forEach( { $0.bump(update) } )
	}
	
	/**
	Clears all flood monitors currently being stored.
	*/
	public func clearAll() {
		limits.removeAll()
	}
}

/**
Defines a set of rules that a FloodLimit class can check for.
*/
public class FloodLimit: Equatable {
	
	// CRITERIA
	/// The type of update to look for when incrementing the hit counter.
	var type: [UpdateType] = []
	
	/// The number of hits currently received within the flood monitor's `duration`.
	var hits: Int
	
	/// The length of time the flood monitor range lasts for.
	var duration: Duration
	
	/// The action to be triggered should the monitor
	var action: () -> ()
	
	// CURRENT STATE
	var currentTime: Date = Date()
	var currentHits: Int = 0
	var actionExecuted: Bool = false
	
	
	/**
	Creates a new FloodMonitor type.
	*/
	init(type: [UpdateType], hits: Int, duration: Duration, action: @escaping () -> ()) {
		
		self.type = type
		self.hits = hits
		self.duration = duration
		self.action = action
	}
	
	/**
	Uses an update to attempt bumping the hits that have occurred on the monitor, in an attempt to trigger
	the action belonging to it.
	*/
	public func bump(_ update: Update) {
		
		// Check that we can actually bump the monitor
		if self.type.contains(update.type) == false { return }
		
		// If so, check the times and hits
		if Date().timeIntervalSince1970 > (currentTime.timeIntervalSince1970 + duration.rawValue) {
			
			resetTime()
			return
		}
		
		// Otherwise bump the hits and check if we've hit the requirement for the action to be triggered.
		currentHits += 1
		
		if currentHits >= hits && actionExecuted == false {
			action()
			actionExecuted = true
		}
	}
	
	/**
	Resets all properties related to measuring hits and action triggering.
	*/
	public func resetTime() {
		
		currentTime = Date()
		currentHits = 0
		actionExecuted = false
	}
	
	
	public static func ==(lhs: FloodLimit, rhs: FloodLimit) -> Bool {
		
		if lhs.type == rhs.type &&
			lhs.hits == rhs.hits &&
			lhs.duration == rhs.duration { return true }
		
		return false
		
	}
}
