//
//  Flood.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Used for monitoring and controlling updates sent to a session by a user.
*/
public class Flood {
	
	/// The currently active set of limits.
	var monitors: [FloodMonitor] = []
	
	init() { }
	
	/**
	Adds a new flood monitor to the class.  If the criteria for the flood monitor you're attempting to add match a
	monitor thats already being used, a new monitor will not be created.
	*/
	public func add(type: [UpdateType], hits: Int, duration: Duration, action: @escaping () -> ()) {
		
		let monitor = FloodMonitor(type: type, hits: hits, duration: duration, action: action)
		if monitors.contains(monitor) { return }
		
		monitors.append(monitor)
		
	}
	
	/**
	Uses an update to attempt bumping the hits on any monitors currently being used, where the
	update is applicable to them.
	*/
	public func bump(_ update: Update) {
		
		monitors.forEach( { $0.bump(update) } )
	}
}

/**
Defines a set of rules that a FloodLimit class can check for.
*/
public class FloodMonitor: Equatable {
	
	// CRITERIA
	var type: [UpdateType] = []
	var hits: Int
	var duration: Duration
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
			
			reset()
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
	Resets all state variables
	*/
	public func reset() {
		
		currentTime = Date()
		currentHits = 0
		actionExecuted = false
	}
	
	
	public static func ==(lhs: FloodMonitor, rhs: FloodMonitor) -> Bool {
		
		if lhs.type == rhs.type &&
			lhs.hits == rhs.hits &&
			lhs.duration == rhs.duration { return true }
		
		return false
		
	}
}
